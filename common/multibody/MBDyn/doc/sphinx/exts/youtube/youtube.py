#-*- coding:utf-8 -*-

#Import urlparse in Python 2 or urllib.parse in Python 3

try:
    import urlparse

except ImportError:
    import urllib.parse as urlparse


from docutils import nodes
from docutils.parsers import rst



class youtube(nodes.General, nodes.Element):
    pass


def is_url(s):

    if s.startswith('http://') or s.startswith('https://'):
        return True

    return False


def get_video_id(url):

    print ('embedding youtube video from: ' + url)

    return urlparse.parse_qs(urlparse.urlparse(url).query)['v'][0]


def visit(self, node):

    #<iframe width="560" height="315" src="https://www.youtube.com/embed/DdoBRinQrEk" frameborder="0" allowfullscreen></iframe>

    video_id = node.video_id
    url = u'https://www.youtube.com/embed/{0}'.format(video_id)

    print ('Embedding using url: ' + url)

    tag = u'''<div class="youtube-iframe"><iframe width="640" height="360" src="{0}" frameborder="0" allowfullscreen="1">&nbsp;</iframe></div>'''.format(url)

    print ('tag is: ' + tag)

    self.body.append(tag)


def depart(self, node):
    pass


class YoutubeDirective(rst.Directive):

    name = 'youtube'
    node_class = youtube

    has_content = False
    required_arguments = 1
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec = {}


    def run(self):

        node = self.node_class()

        arg = self.arguments[0]

        if is_url(arg):
            node.video_id = get_video_id(arg)
        else:
            node.video_id = arg

        return [node]
