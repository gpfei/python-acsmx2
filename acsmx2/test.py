import unittest

from acsmx2.search import Matcher


class MatchTestCase(unittest.TestCase):
    def setUp(self):
        self.matcher = Matcher(1024)

    def test_abc(self):
        for i, pattern in enumerate([
                b'hello',
                b'world',
                b'ld',
            ]):
            self.matcher.add_pattern(pattern, i)
        self.matcher.compile()
        text = b'''
            this is a hello-world-example.
            Even helloooworlddd will be matched.
        '''

        count, words = self.matcher.search(text)
        self.assertEqual(count, 4)
        self.assertEqual(words, b'hello\nld\nhello\nld')

        count, words = self.matcher.search_all(text)
        self.assertEqual(count, 6)
        self.assertEqual(words, b'hello\nld\nworld\nhello\nld\nworld')

    def test_chinese(self):
        for i, pattern in enumerate([
                u'北京'.encode(),
                u'北京大学'.encode(),
                u'大学'.encode(),
            ]):
            self.matcher.add_pattern(pattern, i)
        self.matcher.compile()
        text = u'''我来到北京大学校门口'''.encode()

        count, words = self.matcher.search(text)
        self.assertEqual(count, 2)
        self.assertEqual(words, u'北京\n大学'.encode())

        count, words = self.matcher.search_all(text)
        self.assertEqual(count, 3)
        self.assertEqual(words, u'北京\n大学\n北京大学'.encode())


class MaxSizeTestCase(unittest.TestCase):
    def test_no_enough_length(self):
        matcher = Matcher(8)
        for i, pattern in enumerate([
                b'hello',
                b'world',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(count, 2)
        self.assertEqual(words, b'hello')

    def test_edge_case(self):
        matcher = Matcher(5)
        for i, pattern in enumerate([
                b'hello',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(count, 1)
        self.assertEqual(words, b'')

        matcher = Matcher(6)
        for i, pattern in enumerate([
                b'hello',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(count, 1)
        self.assertEqual(words, b'hello')


if __name__ == '__main__':
    unittest.main()
