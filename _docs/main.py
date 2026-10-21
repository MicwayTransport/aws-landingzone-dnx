import os
import hcl2
import yaml
from pathlib import Path
from uuid import uuid4
import json
from jinja2 import Template
from pprint import pprint
import re

def resolve_hcl_variables(data, globals_data, accounts_data, environments_data, account_name, region):
    """
    Recursively resolve HCL variable references in the data structure.
    Replaces ${local.globals.*}, ${local.accounts.*}, ${local.current_account.*}, ${local.environments.*} with actual values.
    """
    if isinstance(data, dict):
        return {k: resolve_hcl_variables(v, globals_data, accounts_data, environments_data, account_name, region) for k, v in data.items()}
    elif isinstance(data, list):
        return [resolve_hcl_variables(item, globals_data, accounts_data, environments_data, account_name, region) for item in data]
    elif isinstance(data, str):
        # Get current account info
        current_account = accounts_data['accounts'].get(account_name, {})
        
        # Replace common HCL variable patterns
        result = data
        
        # Replace ${local.globals.*}
        globals_vars = {
            'local.globals.default_aws_region': region,
            'local.globals.aws_region': region,
            'local.globals.org_name': globals_data.get('org_name'),
            'local.globals.organization.name': globals_data.get('organization', {}).get('name'),
        }
        
        # Replace ${local.current_account.*}
        current_account_vars = {
            'local.current_account.name': account_name,
            'local.current_account.account_id': current_account.get('account_id', 'UNKNOWN'),
        }
        
        # Replace ${local.accounts.accounts.*} and ${local.environments.*}
        for var_name, var_value in {**globals_vars, **current_account_vars}.items():
            result = result.replace(f'${{{var_name}}}', str(var_value))
        
        # Replace account lookups like ${local.accounts.accounts.audit.account_id}
        account_pattern = r'\$\{local\.accounts\.accounts\.([^.]+)\.account_id\}'
        matches = re.findall(account_pattern, result)
        for match in matches:
            acc_id = accounts_data['accounts'].get(match, {}).get('account_id', 'UNKNOWN')
            result = result.replace(f'${{local.accounts.accounts.{match}.account_id}}', acc_id)
        
        # Replace environment patterns like ${local.environments.domain_patterns.}
        env_pattern = r'\$\{local\.environments\.(domain_patterns|vpc_cidrs)\.([^}]+)\}'
        matches = re.findall(env_pattern, result)
        for pattern_type, env_name in matches:
            env_value = environments_data.get(pattern_type, {}).get(env_name, f'UNKNOWN_{env_name}')
            result = result.replace(f'${{local.environments.{pattern_type}.{env_name}}}', str(env_value))
        
        return result
    else:
        return data

def define_env(env):
    stack_names = [
        'identity',
        'network',
        'platform',
        'platform-data',
        'security',
        'dns-delegation',
    ]

    data = {}

    root_path = Path().resolve().parent
    client_path = Path(root_path, '_workspaces')
    assert client_path.exists()
    
    # Load globals.hcl
    globals_path = Path(client_path, 'globals.hcl')
    with globals_path.open() as f:
        globals_hcl = hcl2.load(f)
        globals_data = globals_hcl.get('locals', [{}])[0] if globals_hcl.get('locals') else {}
    
    # Load accounts.hcl
    accounts_path = Path(client_path, 'accounts.hcl')
    with accounts_path.open() as f:
        accounts_hcl = hcl2.load(f)
        accounts_data = accounts_hcl.get('locals', [{}])[0] if accounts_hcl.get('locals') else {}
    
    # Load environments.hcl
    environments_path = Path(client_path, 'environments.hcl')
    with environments_path.open() as f:
        environments_hcl = hcl2.load(f)
        environments_data = environments_hcl.get('locals', [{}])[0] if environments_hcl.get('locals') else {}

    for stack_name in stack_names:
        workspaces = data.setdefault('stacks', {}).setdefault(stack_name, {}).setdefault('workspaces', {})
        
        # New pattern: account/region/stack/terragrunt.hcl
        # Example: stage/ap-southeast-2/identity/terragrunt.hcl
        stack_config_paths = Path(client_path).glob(f'*/*/{stack_name}/terragrunt.hcl')
        
        for stack_config_path in stack_config_paths:
            with stack_config_path.open() as f:
                stack_config_data = hcl2.load(f)
            
            # Extract account and region from path
            # path structure: _workspaces/account/region/stack/terragrunt.hcl
            account_name = stack_config_path.parent.parent.parent.stem
            region = stack_config_path.parent.parent.stem
            workspace_name = f"{account_name}_{region}"
            
            # Resolve HCL variables in inputs
            # HCL2 parser returns 'inputs' as a dictionary
            inputs = stack_config_data.get('inputs', {})
            resolved_inputs = resolve_hcl_variables(inputs, globals_data, accounts_data, environments_data, account_name, region)
            
            workspaces[workspace_name] = resolved_inputs

        # New pattern for outputs: account/region/stack/.outputs.json
        output_paths = Path(client_path).glob(f'*/*/{stack_name}/.outputs.json')
        for output_path in output_paths:
            # Skip empty or invalid JSON files
            try:
                with output_path.open() as json_file:
                    content = json_file.read().strip()
                    if not content:
                        continue
                    output_data = json.loads(content)
            except (ValueError, json.JSONDecodeError):
                # Skip invalid JSON files
                continue
                
            for key, value in output_data.items():
                if isinstance(value, dict) and 'value' in value:
                    output_data[key] = value['value']
            
            # Extract account and region from path
            account_name = output_path.parent.parent.parent.stem
            region = output_path.parent.parent.stem
            workspace_name = f"{account_name}_{region}"
            
            output = data.setdefault('outputs', {}).setdefault(stack_name, {})
            output[workspace_name] = output_data

    # Ensure outputs structure exists even if empty
    if 'outputs' not in data:
        data['outputs'] = {}
    
    # Ensure each stack has an outputs entry even if empty
    for stack_name in stack_names:
        if stack_name not in data['outputs']:
            data['outputs'][stack_name] = {}
    
    # write data to file
    data_path = Path('.data.yml')
    with data_path.open('w') as f:
        yaml.dump(data, f)

    env.variables.update(data)
    update_nav(env)

def update_nav(env):
    env.conf.data['nav'] = _update_nav(env.variables, env.conf.data['nav'])

def _update_nav(vars, data):
    if isinstance(data, dict):
        return {k: _update_nav(vars, v) for k, v in data.items() if valid_nav(vars, v)}
    elif isinstance(data, list):
        return list(filter(None, [_update_nav(vars, v) for v in data if valid_nav(vars, v)]))
    return data.split(' if ', maxsplit=1)[0].rstrip()

def valid_nav(vars, nav: str):
    if isinstance(nav, str):
        if ' if ' in nav:
            expr = r"{{" + nav.split(' if ', maxsplit=1)[1].strip() + r"}}"
            value = Template(expr).render(vars)
            assert value in ['True', 'False']
            return value == 'True'
    return True
