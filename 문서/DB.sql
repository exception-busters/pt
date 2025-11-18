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
CREATE TABLE public.dietgoal (
  diet_id integer NOT NULL DEFAULT nextval('dietgoal_diet_id_seq'::regclass),
  user_id uuid,
  daily_calorie_target integer,
  diet_type character varying,
  meals_per_day integer,
  daily_water_ml integer,
  dietary_restrictions ARRAY,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT dietgoal_pkey PRIMARY KEY (diet_id),
  CONSTRAINT dietgoal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
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
CREATE TABLE public.exercisegoal (
  goal_id integer NOT NULL DEFAULT nextval('exercisegoal_goal_id_seq'::regclass),
  user_id uuid,
  goal_type character varying,
  level character varying,
  weekly_days integer,
  daily_duration_min integer,
  preferred_types ARRAY,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT exercisegoal_pkey PRIMARY KEY (goal_id),
  CONSTRAINT exercisegoal_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
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
  CONSTRAINT feedback_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.routine_record(session_id),
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
  my_food_id integer NOT NULL DEFAULT nextval('myfood_my_food_id_seq'::regclass),
  user_id uuid,
  food_id integer,
  is_favorite boolean,
  added_at timestamp without time zone,
  CONSTRAINT myfood_pkey PRIMARY KEY (my_food_id),
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
CREATE TABLE public.point_transaction (
  transaction_id integer NOT NULL DEFAULT nextval('point_transaction_transaction_id_seq'::regclass),
  user_id uuid,
  change_amount numeric,
  reason character varying,
  created_at timestamp without time zone,
  CONSTRAINT point_transaction_pkey PRIMARY KEY (transaction_id),
  CONSTRAINT point_transaction_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.posedata (
  pose_id integer NOT NULL DEFAULT nextval('posedata_pose_id_seq'::regclass),
  session_id integer,
  frame_index integer,
  keypoints_json json,
  CONSTRAINT posedata_pkey PRIMARY KEY (pose_id),
  CONSTRAINT posedata_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.routine_record(session_id)
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
CREATE TABLE public.routine (
  routine_id integer NOT NULL DEFAULT nextval('routine_routine_id_seq'::regclass),
  user_id uuid,
  title character varying,
  description text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT routine_pkey PRIMARY KEY (routine_id),
  CONSTRAINT routine_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.routine_exercise (
  routine_ex_id integer NOT NULL DEFAULT nextval('routine_exercise_routine_ex_id_seq'::regclass),
  routine_id integer,
  exercise_id integer,
  sets integer,
  reps integer,
  rest_time_sec integer,
  CONSTRAINT routine_exercise_pkey PRIMARY KEY (routine_ex_id),
  CONSTRAINT routine_exercise_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.routine(routine_id),
  CONSTRAINT routine_exercise_exercise_id_fkey FOREIGN KEY (exercise_id) REFERENCES public.exercise(exercise_id)
);
CREATE TABLE public.routine_record (
  session_id integer NOT NULL DEFAULT nextval('routine_record_session_id_seq'::regclass),
  user_id uuid,
  routine_id integer,
  start_time timestamp without time zone,
  end_time timestamp without time zone,
  total_calories numeric,
  completion_method character varying DEFAULT 'pose_assisted',
  manual_notes text,
  perceived_intensity smallint,
  is_user_reported boolean DEFAULT false,
  CONSTRAINT routine_record_pkey PRIMARY KEY (session_id),
  CONSTRAINT routine_record_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT routine_record_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.routine(routine_id)
);

CREATE TABLE public.routine_schedule (
  schedule_id integer NOT NULL DEFAULT nextval('routine_schedule_schedule_id_seq'::regclass),
  user_id uuid NOT NULL,
  routine_id integer NOT NULL,
  weekday smallint NOT NULL CHECK (weekday BETWEEN 0 AND 6),
  start_time time without time zone,
  sort_order integer DEFAULT 0,
  is_active boolean DEFAULT true,
  note text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT routine_schedule_pkey PRIMARY KEY (schedule_id),
  CONSTRAINT routine_schedule_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT routine_schedule_routine_id_fkey FOREIGN KEY (routine_id) REFERENCES public.routine(routine_id),
  CONSTRAINT routine_schedule_unique UNIQUE (user_id, weekday, routine_id, sort_order)
);
CREATE TABLE public.user_challenge (
  user_challenge_id integer NOT NULL DEFAULT nextval('user_challenge_user_challenge_id_seq'::regclass),
  user_id uuid,
  challenge_id integer,
  progress_value numeric,
  completed boolean,
  joined_at timestamp without time zone,
  CONSTRAINT user_challenge_pkey PRIMARY KEY (user_challenge_id),
  CONSTRAINT user_challenge_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT user_challenge_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.challenge(challenge_id)
);
CREATE TABLE public.user_content_access (
  access_id integer NOT NULL DEFAULT nextval('user_content_access_access_id_seq'::regclass),
  user_id uuid,
  item_id integer,
  has_access boolean,
  granted_at timestamp without time zone,
  CONSTRAINT user_content_access_pkey PRIMARY KEY (access_id),
  CONSTRAINT user_content_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT user_content_access_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(item_id)
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
  gender character varying,
  age integer,
  height numeric,
  weight numeric,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT userprofile_pkey PRIMARY KEY (user_id),
  CONSTRAINT userprofile_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.users (
  user_id uuid NOT NULL,
  email character varying NOT NULL UNIQUE,
  nickname character varying,
  profile_image text,
  join_date timestamp without time zone DEFAULT now(),
  profile_completed boolean DEFAULT false,
  CONSTRAINT users_pkey PRIMARY KEY (user_id)
);
