-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.badge (
  badge_id integer NOT NULL DEFAULT nextval('badge_badge_id_seq'::regclass),
  name character varying,
  description text,
  icon_url character varying,
  CONSTRAINT badge_pkey PRIMARY KEY (badge_id)
);
CREATE TABLE public.challenge (
  challenge_id integer NOT NULL DEFAULT nextval('challenge_challenge_id_seq'::regclass),
  title character varying,
  description text,
  goal_value numeric,
  duration_days integer,
  reward_points numeric,
  CONSTRAINT challenge_pkey PRIMARY KEY (challenge_id)
);
CREATE TABLE public.exercise (
  exercise_id integer NOT NULL DEFAULT nextval('exercise_exercise_id_seq'::regclass),
  name character varying,
  body_part character varying,
  description text,
  difficulty character varying,
  video_url character varying,
  CONSTRAINT exercise_pkey PRIMARY KEY (exercise_id)
);
CREATE TABLE public.feedback (
  feedback_id integer NOT NULL DEFAULT nextval('feedback_feedback_id_seq'::regclass),
  session_id integer,
  exercise_id integer,
  set_num integer,
  feedback_text text,
  score numeric,
  created_at timestamp without time zone,
  CONSTRAINT feedback_pkey PRIMARY KEY (feedback_id),
  CONSTRAINT feedback_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.workoutsession(session_id),
  CONSTRAINT feedback_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES public.exercise(exercise_id)
);
CREATE TABLE public.foodinfo (
  food_id integer NOT NULL DEFAULT nextval('foodinfo_food_id_seq'::regclass),
  name character varying,
  calories numeric,
  protein numeric,
  carbs numeric,
  fat numeric,
  CONSTRAINT foodinfo_pkey PRIMARY KEY (food_id)
);
CREATE TABLE public.goal (
  goal_id integer NOT NULL DEFAULT nextval('goal_goal_id_seq'::regclass),
  user_id uuid,
  goal_type character varying,
  target_value numeric,
  current_value numeric,
  start_date date,
  end_date date,
  CONSTRAINT goal_pkey PRIMARY KEY (goal_id),
  CONSTRAINT goal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.item (
  item_id integer NOT NULL DEFAULT nextval('item_item_id_seq'::regclass),
  name character varying,
  description text,
  price_point numeric,
  image_url character varying,
  is_premium boolean,
  CONSTRAINT item_pkey PRIMARY KEY (item_id)
);
CREATE TABLE public.myfood (
  myfood_id integer NOT NULL DEFAULT nextval('myfood_myfood_id_seq'::regclass),
  user_id uuid,
  food_id integer,
  is_favorite boolean,
  added_at timestamp without time zone,
  CONSTRAINT myfood_pkey PRIMARY KEY (myfood_id),
  CONSTRAINT myfood_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT myfood_food_id_fkey FOREIGN KEY (food_id) REFERENCES public.foodinfo(food_id)
);
CREATE TABLE public.notification (
  noti_id integer NOT NULL DEFAULT nextval('notification_noti_id_seq'::regclass),
  user_id uuid,
  type character varying,
  message text,
  created_at timestamp without time zone,
  is_read boolean,
  CONSTRAINT notification_pkey PRIMARY KEY (noti_id),
  CONSTRAINT notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.nutritionsummary (
  summary_id integer NOT NULL DEFAULT nextval('nutritionsummary_summary_id_seq'::regclass),
  user_id uuid,
  date date,
  total_calories numeric,
  total_protein numeric,
  total_carbs numeric,
  total_fat numeric,
  CONSTRAINT nutritionsummary_pkey PRIMARY KEY (summary_id),
  CONSTRAINT nutritionsummary_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.pointtransaction (
  transaction_id integer NOT NULL DEFAULT nextval('pointtransaction_transaction_id_seq'::regclass),
  user_id uuid,
  change_amount numeric,
  reason character varying,
  created_at timestamp without time zone,
  CONSTRAINT pointtransaction_pkey PRIMARY KEY (transaction_id),
  CONSTRAINT pointtransaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.posedata (
  pose_id integer NOT NULL DEFAULT nextval('posedata_pose_id_seq'::regclass),
  session_id integer,
  frame_index integer,
  keypoints_json json,
  CONSTRAINT posedata_pkey PRIMARY KEY (pose_id),
  CONSTRAINT posedata_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.workoutsession(session_id)
);
CREATE TABLE public.progress (
  progress_id integer NOT NULL DEFAULT nextval('progress_progress_id_seq'::regclass),
  goal_id integer,
  date date,
  value numeric,
  CONSTRAINT progress_pkey PRIMARY KEY (progress_id),
  CONSTRAINT progress_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES public.goal(goal_id)
);
CREATE TABLE public.purchase (
  purchase_id integer NOT NULL DEFAULT nextval('purchase_purchase_id_seq'::regclass),
  user_id uuid,
  item_id integer,
  purchase_date timestamp without time zone,
  CONSTRAINT purchase_pkey PRIMARY KEY (purchase_id),
  CONSTRAINT purchase_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT purchase_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(item_id)
);
CREATE TABLE public.ranking (
  rank_id integer NOT NULL DEFAULT nextval('ranking_rank_id_seq'::regclass),
  user_id uuid,
  total_workouts integer,
  total_calories numeric,
  accuracy_avg numeric,
  rank_position integer,
  updated_at timestamp without time zone,
  CONSTRAINT ranking_pkey PRIMARY KEY (rank_id),
  CONSTRAINT ranking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.routineexercise (
  routine_ex_id integer NOT NULL DEFAULT nextval('routineexercise_routine_ex_id_seq'::regclass),
  routine_id integer,
  exercise_id integer,
  sets integer,
  reps integer,
  rest_time_sec integer,
  CONSTRAINT routineexercise_pkey PRIMARY KEY (routine_ex_id),
  CONSTRAINT routineexercise_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.workoutroutine(routine_id),
  CONSTRAINT routineexercise_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES public.exercise(exercise_id)
);
CREATE TABLE public.userbadge (
  user_badge_id integer NOT NULL DEFAULT nextval('userbadge_user_badge_id_seq'::regclass),
  user_id uuid,
  badge_id integer,
  earned_at timestamp without time zone,
  CONSTRAINT userbadge_pkey PRIMARY KEY (user_badge_id),
  CONSTRAINT userbadge_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT userbadge_badge_id_fkey FOREIGN KEY (badge_id) REFERENCES public.badge(badge_id)
);
CREATE TABLE public.userchallenge (
  user_challenge_id integer NOT NULL DEFAULT nextval('userchallenge_user_challenge_id_seq'::regclass),
  user_id uuid,
  challenge_id integer,
  progress_value numeric,
  completed boolean,
  joined_at timestamp without time zone,
  CONSTRAINT userchallenge_pkey PRIMARY KEY (user_challenge_id),
  CONSTRAINT userchallenge_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT userchallenge_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.challenge(challenge_id)
);
CREATE TABLE public.usercontentaccess (
  access_id integer NOT NULL DEFAULT nextval('usercontentaccess_access_id_seq'::regclass),
  user_id uuid,
  item_id integer,
  has_access boolean,
  granted_at timestamp without time zone,
  CONSTRAINT usercontentaccess_pkey PRIMARY KEY (access_id),
  CONSTRAINT usercontentaccess_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT usercontentaccess_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(item_id)
);
CREATE TABLE public.usermeal (
  meal_id integer NOT NULL DEFAULT nextval('usermeal_meal_id_seq'::regclass),
  user_id uuid,
  food_id integer,
  meal_time timestamp without time zone,
  quantity numeric,
  CONSTRAINT usermeal_pkey PRIMARY KEY (meal_id),
  CONSTRAINT usermeal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT usermeal_food_id_fkey FOREIGN KEY (food_id) REFERENCES public.foodinfo(food_id)
);
CREATE TABLE public.userprofile (
  user_id uuid NOT NULL,
  level integer,
  age integer,
  height numeric,
  weight numeric,
  gender character varying,
  profile_image character varying,
  bio text,
  CONSTRAINT userprofile_pkey PRIMARY KEY (user_id),
  CONSTRAINT userprofile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.users (
  user_id uuid NOT NULL,
  email character varying NOT NULL UNIQUE,
  nickname character varying,
  join_date timestamp without time zone,
  CONSTRAINT users_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.workoutrecords (
  record_id integer NOT NULL DEFAULT nextval('workoutrecords_record_id_seq'::regclass),
  session_id integer,
  exercise_id integer,
  set_num integer,
  reps_done integer,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  calories_burned numeric,
  CONSTRAINT workoutrecords_pkey PRIMARY KEY (record_id),
  CONSTRAINT workoutrecords_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.workoutsession(session_id),
  CONSTRAINT workoutrecords_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES public.exercise(exercise_id)
);
CREATE TABLE public.workoutroutine (
  routine_id integer NOT NULL DEFAULT nextval('workoutroutine_routine_id_seq'::regclass),
  user_id uuid,
  title character varying,
  description text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT workoutroutine_pkey PRIMARY KEY (routine_id),
  CONSTRAINT workoutroutine_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.workoutsession (
  session_id integer NOT NULL DEFAULT nextval('workoutsession_session_id_seq'::regclass),
  user_id uuid,
  routine_id integer,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  total_calories numeric,
  CONSTRAINT workoutsession_pkey PRIMARY KEY (session_id),
  CONSTRAINT workoutsession_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT workoutsession_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.workoutroutine(routine_id)
);