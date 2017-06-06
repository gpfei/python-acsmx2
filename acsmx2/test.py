import unittest

from acsmx2.search import Matcher, MatchedWord


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
        self.assertEqual(len(words), 4)
        self.assertEqual(len(words), count)
        self.assertListEqual(words, [
            MatchedWord(23, b'hello'),
            MatchedWord(32, b'ld'),
            MatchedWord(61, b'hello'),
            MatchedWord(71, b'ld'),
        ])

        count, words = self.matcher.search_all(text)
        self.assertEqual(len(words), 6)
        self.assertEqual(len(words), count)
        self.assertListEqual(words, [
            MatchedWord(23, b'hello'),
            MatchedWord(32, b'ld'),
            MatchedWord(29, b'world'),
            MatchedWord(61, b'hello'),
            MatchedWord(71, b'ld'),
            MatchedWord(68, b'world'),
        ])

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
        self.assertEqual(len(words), 2)
        self.assertEqual(len(words), count)
        self.assertListEqual(words, [
            MatchedWord(9, '北京'.encode()),
            MatchedWord(15, '大学'.encode()),
        ])

        count, words = self.matcher.search_all(text)
        self.assertEqual(len(words), 3)
        self.assertEqual(len(words), count)
        self.assertListEqual(words, [
            MatchedWord(9, '北京'.encode()),
            MatchedWord(15, '大学'.encode()),
            MatchedWord(9, '北京大学'.encode()),
        ])


class MaxSizeTestCase(unittest.TestCase):
    def test_no_enough_length(self):
        matcher = Matcher(10)
        for i, pattern in enumerate([
                b'hello',
                b'world',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(count, 2)
        self.assertEqual(len(words), 1)
        self.assertListEqual(words, [MatchedWord(10, b'hello')])

    def test_edge_case(self):
        matcher = Matcher(8)
        for i, pattern in enumerate([
                b'hello',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(len(words), 0)
        self.assertEqual(count, 1)
        self.assertListEqual(words, [])

        matcher = Matcher(9)
        for i, pattern in enumerate([
                b'hello',
            ]):
            matcher.add_pattern(pattern, i)
        matcher.compile()
        text = b'this is a hello-world-example.'

        count, words = matcher.search(text)
        self.assertEqual(len(words), 1)
        self.assertEqual(count, 1)
        self.assertListEqual(words, [MatchedWord(10, b'hello')])


if __name__ == '__main__':
    unittest.main()
