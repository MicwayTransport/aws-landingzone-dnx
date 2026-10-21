build: clean
	docker compose run mkdocs make _build

serve:
	docker compose run -p 8000:8000 mkdocs make _serve

shell:
	docker compose run mkdocs /bin/sh

_build:
	@echo mkdocs build
	ENABLE_PDF_EXPORT=1 mkdocs build
	htmlark site/print_page.html -o docs.html
	mv docs.html ../_docs
	mv docs.pdf ../_docs

_serve:
	ENABLE_PDF_EXPORT=0 mkdocs serve -a 0.0.0.0:8000

.PHONY: collect build clean _build _serve _pdf
