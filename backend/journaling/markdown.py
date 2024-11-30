from markdown_it import MarkdownIt

def parse_markdown(content):
    md = MarkdownIt()
    return md.render(content)

