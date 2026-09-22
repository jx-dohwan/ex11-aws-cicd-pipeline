SET NAMES utf8mb4;

-- 1. 데이터베이스 생성 및 선택 (대문자 STUDY -> 소문자 study)
DROP DATABASE IF EXISTS study;
CREATE DATABASE IF NOT EXISTS study DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE study;

-- 2. 계정 생성 및 권한 부여
CREATE USER IF NOT EXISTS 'std04'@'%' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON study.* TO 'std04'@'%';
FLUSH PRIVILEGES;

-- 3. 가입자 정보 테이블 생성 (대문자 TMEMBER -> 소문자 tmember)
DROP TABLE IF EXISTS tmember;
CREATE TABLE IF NOT EXISTS tmember (
    fid         varchar(12)     not null    comment '가입자 아이디',
    fpass       varchar(20)     not null    comment '가입자 비밀번호',
    fname       nvarchar(20)    not null    comment '가입자 이름',
    femail      varchar(50)     not null    comment '가입자 이메일 주소',
    fphone      varchar(13)     not null    comment '가입자 연락처',
    faddr1      nvarchar(30)    not null    comment '가입자 기본주소',
    faddr2      nvarchar(20)    not null    comment '가입자 상세주소',
    fbirthday   date            not null    comment '가입자 생년월일',
    fgender     set('남','여')  not null    comment '가입자 성별',
    fdate       datetime        not null    comment '가입일',
    PRIMARY KEY (fid)
) COMMENT='AWS RDS 서비스 테스트용 테이블';

-- 가입자 초기 데이터 입력
INSERT INTO tmember (fid, fpass, fname, femail, fphone, faddr1, faddr2, fbirthday, fgender, fdate) VALUES
('mzc-000', '1111', '김유신', 'adc@mz.co.kr', '010-1111-1111', '서울특별시 강남구 논현로', '메가존빌딩 101호', '2002-07-26', '여', now()),
('mzc-111', '1111', '이순신', 'bcd@mz.co.kr', '010-2222-2222', '서울특별시 강남구 강남대로', '제니스빌딩 210호', '2002-07-26', '여', now()),
('mzc-333', '1111', '홍길동', 'cde@mz.co.kr', '010-3333-3333', '서울특별시 강남구 삼성로', '금정빌딩 310호', '2002-07-26', '여', now()),
('mzc-444', '1111', '강감찬', 'def@mz.co.kr', '010-4444-4444', '서울특별시 강남구 역삼동', '빅데이터빌딩 410호', '2002-07-26', '여', now()),
('mzc-555', '1111', '세종',   'efg@mz.co.kr', '010-5555-5555', '서울특별시 강남구 청담동', '에이아이빌딩 510호', '2002-07-26', '여', now()),
('mzc-666', '1111', '정조',   'fgh@mz.co.kr', '010-6666-6666', '경기도 수원시',           '아이오티빌딩 610호', '2002-07-26', '여', now()),
('mzc-777', '1111', '김종신', 'ghi@mz.co.kr', '010-7777-7777', '경기도 의정부시',         '스마트시티빌딩 710호', '2002-07-26', '여', now()),
('mzc-888', '1111', '아이유', 'hij@mz.co.kr', '010-8888-8888', '경기도 안양시',           '클라우드빌딩 810호', '2002-07-26', '여', now()),
('mzc-999', '1111', '안중근', 'ijk@mz.co.kr', '010-9999-9999', '경기도 군포시',           '그램빌딩 210호',     '2002-07-26', '여', now()),
('adc-tot', '2222', '애쓴이', 'lmn@megazone.com', '010-0000-0000', '경기도 화성시',       '메가존빌딩 2층',     '2004-05-21', '남', now());

-- 4. 성적 관리 테이블 생성 (대문자 TTEST -> 소문자 ttest)
DROP TABLE IF EXISTS ttest;
CREATE TABLE IF NOT EXISTS ttest (
    fidx        int             not null    auto_increment  comment '일련번호, 자동증가',
    fid         varchar(12)     not null    comment '가입자 아이디',
    fkor        smallint        not null    default 0       comment '국어점수',
    feng        smallint        not null    default 0       comment '영어점수',
    fmat        smallint        not null    default 0       comment '수학점수',
    fdate       datetime        not null    comment '성적입력일',
    PRIMARY KEY (fidx)
) COMMENT='수강생의 성적을 관리하기 위한 테이블';

-- 성적 초기 데이터 입력
INSERT INTO ttest (fid, fkor, feng, fmat, fdate) VALUES
('mzc-000', 99, 88, 77, now()),
('mzc-111', 88, 77, 60, now());

-- 5. 성적 결과 조회용 뷰 생성 (대문자 VRESULT -> 소문자 vresult)
DROP VIEW IF EXISTS vresult;
CREATE VIEW vresult AS
    SELECT 
        a.fidx,
        a.fid, 
        b.fname, 
        b.fgender, 
        a.fkor, 
        a.feng, 
        a.fmat, 
        (a.fkor + a.feng + a.fmat) AS ftot, 
        ROUND((a.fkor + a.feng + a.fmat) / 3, 1) AS favg, 
        a.fdate 
    FROM ttest a 
    LEFT JOIN tmember b ON a.fid = b.fid
    ORDER BY b.fid ASC;