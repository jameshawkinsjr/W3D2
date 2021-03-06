require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
	include Singleton

	def initialize
		super('questions.db')
		self.type_translation = true
		self.results_as_hash = true
	end
end


#####################


class Question
	attr_accessor :id, :title, :body, :user_id

	def self.find_by_id(id)
		data = QuestionsDatabase.instance.execute("SELECT * FROM questions WHERE id = '#{id}'")
		data.map { |datum| Question.new(datum)}
	end

	def self.find_by_author_id(author_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
			SELECT 
				*
			FROM
				questions
			WHERE
				user_id = ?
		SQL

		data.map { |datum| Question.new(datum)}
	end
	
	def self.most_followed(n)
		QuestionFollow.most_followed_questions(n)
	end
	
	def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
	end
	
	def create
		raise "#{self} already in database" if self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.user_id)
			INSERT INTO
				questions (title, body, user_id)
			VALUES
				(?, ?, ?)
		SQL
		self.id = QuestionsDatabase.instance.last_insert_row_id
	end

	def update
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.title, self.body, self.user_id)
			UPDATE
				questions
			SET
				title = ?, body = ?, user_id = ?
			WHERE
				id = ?
		SQL
	end

	def author
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.user_id)
			SELECT
				*
			FROM
				questions
			WHERE
				user_id = ?
		SQL
	end

	def replies
		Reply.find_by_question_id(self.id)
	end

	def followers
		QuestionFollow.followers_for_question_id(@id)
	end

end

#####################


class User
	attr_accessor :id, :fname, :lname

	def self.find_by_name(fname, lname)
		data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
			SELECT 
				*
			FROM
				users
			WHERE
				fname = ? AND
				lname = ?
		SQL
		data.map { |datum| User.new(datum)}
	end
	
	def self.find_by_id(id)
		data = QuestionsDatabase.instance.execute(<<-SQL, id)
			SELECT 
				*
			FROM
				users
			WHERE
				id = ?
		SQL
		data.map { |datum| User.new(datum)}
	end

	def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
	end
	
	def create
		raise "#{self} already in database" if self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
			INSERT INTO
				users (fname, lname)
			VALUES
				(?, ?)
		SQL
		self.id = QuestionsDatabase.instance.last_insert_row_id
	end

	def update
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
			UPDATE
				users
			SET
				fname = ?, lname = ?
			WHERE
				id = ?
		SQL
	end

	def authored_questions
		Question.find_by_author_id(self.id)
	end

	def authored_replies
		Reply.find_by_user_id(self.id)
	end

	def followed_questions
		QuestionFollow.followed_questions_for_user_id(self.id)
	end
end


#####################


class QuestionFollow
	attr_accessor :id, :question_id, :user_id

	def self.followers_for_question_id(question_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
			SELECT
				users.*
			FROM
				users
			JOIN
				question_follows ON question_follows.user_id = users.id
			WHERE
				question_follows.question_id = ?
		SQL
		data.map { |datum| User.new(datum)}
	end

	def self.followed_questions_for_user_id(user_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
			SELECT
				questions.*
			FROM
				questions
			JOIN
				question_follows ON question_follows.question_id = questions.id
			WHERE
				question_follows.user_id = ?
		SQL
		data.map { |datum| Question.new(datum)}
	end

	def self.most_followed_questions(n)
		data = QuestionsDatabase.instance.execute(<<-SQL, n)
			SELECT 
				questions.*
			FROM 
				questions
			JOIN
				question_follows ON questions.id = question_follows.question_id
			GROUP BY 
				questions.id 
			ORDER BY COUNT(*) DESC 
			LIMIT ?
		SQL
		data.map { |datum| Question.new(datum)}
	end

	def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
	end
	
	def create
		raise "#{self} already in database" if self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.user_id)
			INSERT INTO
				question_follows (question_id, user_id)
			VALUES
				(?, ?)
		SQL
		self.id = QuestionsDatabase.instance.last_insert_row_id
	end

	def update
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.user_id)
			UPDATE
				question_follows
			SET
				question_id = ?, user_id = ?
			WHERE
				id = ?
		SQL
	end
end

#####################


class QuestionLike
	attr_accessor :id, :question_id, :user_id

	def self.likers_for_question_id(question_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
			SELECT
				users.*
			FROM
				users
			JOIN
				question_likes ON question_likes.user_id = users.id
			WHERE
				question_likes.question_id = ?
		SQL
		data.map { |datum| User.new(datum)}
	end

	def self.num_likes_for_question_id(question_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
			SELECT
				COUNT(*)
			FROM
				users
			JOIN
				question_likes ON question_likes.user_id = users.id
			WHERE
					question_likes.question_id = ?
			GROUP BY
				question_likes.question_id
		SQL
		data[0].values[0]
	end

	

	def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
	end
	
	def create
		raise "#{self} already in database" if self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.user_id)
			INSERT INTO
				question_likes (question_id, user_id)
			VALUES
				(?, ?)
		SQL
		self.id = QuestionsDatabase.instance.last_insert_row_id
	end

	def update
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.user_id)
			UPDATE
				question_likes
			SET
				question_id = ?, user_id = ?
			WHERE
				id = ?
		SQL
	end
end

#####################


class Reply
	attr_accessor :id, :question_id, :parent_id, :user_id, :body

	def self.find_by_user_id(user_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
			SELECT 
				*
			FROM
				replies
			WHERE
				user_id = ?
		SQL
		
		data.map { |datum| Reply.new(datum)}
	end

	def self.find_by_question_id(question_id)
		data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
			SELECT 
				*
			FROM
				replies
			WHERE
				question_id = ?
		SQL
		
		data.map { |datum| Reply.new(datum)}
	end

	def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
	end
	
	def create
		raise "#{self} already in database" if self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.parent_id, self.user_id, self.body)
			INSERT INTO
				replies (question_id, parent_id, user_id, body)
			VALUES
				(?, ?, ?, ?)
		SQL
		self.id = QuestionsDatabase.instance.last_insert_row_id
	end

	def update
		raise "#{self} not in database" unless self.id
		QuestionsDatabase.instance.execute(<<-SQL, self.question_id, self.parent_id, self.user_id, self.body)
			UPDATE
				replies
			SET
				question_id = ?, parent_id = ?, user_id = ?, body = ?
			WHERE
				id = ?
		SQL
	end

	def author
		User.find_by_id(@user_id)
	end

	def question
		Question.find_by_id(@question_id)
	end

	def parent_reply
		data = QuestionsDatabase.instance.execute(<<-SQL)
			SELECT 
				*
			FROM
				replies
			WHERE
				id = #{@parent_id}
		SQL
		data.map { |datum| Reply.new(datum)}
	end

	def child_replies
		data = QuestionsDatabase.instance.execute(<<-SQL)
			SELECT 
				*
			FROM
				replies
			WHERE
				parent_id = #{@id}
		SQL
		data.map { |datum| Reply.new(datum)}
	end

end