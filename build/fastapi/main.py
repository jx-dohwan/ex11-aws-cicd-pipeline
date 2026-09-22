from fastapi import FastAPI, Query, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pymysql
from pymysql.cursors import DictCursor
import os
from typing import Optional

app = FastAPI(title="Student Score Management API")

# CORS 설정 (모든 도메인 허용)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------
# 1. 데이터베이스 연결 설정 (소문자 study 적용)
# ---------------------------------------------------------
DB_HOST = os.getenv("DB_HOST", "mysql")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "std04")
DB_PASSWORD = os.getenv("DB_PASSWORD", "1234")
DB_NAME = os.getenv("DB_NAME", "study")  # 1. 수정됨

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=True
    )

# ---------------------------------------------------------
# 2. 헬스 체크 엔드포인트 (ALB 상태 검사용)
# ---------------------------------------------------------
@app.get("/health")
def health_check():
    return {"status": "ok"}

# ---------------------------------------------------------
# 3. 교육생 목록 조회 (tmember 조회)
# ---------------------------------------------------------
@app.get("/members")
def get_members():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT fid, fname FROM tmember ORDER BY fid ASC")  # 2. 수정됨
            members = cursor.fetchall()
            return members
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# ---------------------------------------------------------
# 4. 성적 목록 조회 (vresult 뷰 조회)
# ---------------------------------------------------------
@app.get("/loadresult")
def load_results(uid: Optional[str] = Query(None)):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            base_sql = """
                SELECT 
                    fidx, 
                    fid, 
                    fname, 
                    fgender, 
                    fkor, 
                    feng, 
                    fmat, 
                    ftot, 
                    CAST(favg AS DOUBLE) AS favg, 
                    DATE_FORMAT(fdate, '%Y-%m-%d %H:%i:%s') AS fdate 
                FROM vresult
            """  # 3. 수정됨
            
            if uid and uid.strip() != "":
                base_sql += " WHERE fid = %s ORDER BY fidx DESC"
                cursor.execute(base_sql, (uid,))
            else:
                base_sql += " ORDER BY fidx DESC"
                cursor.execute(base_sql)
                
            results = cursor.fetchall()
            return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# ---------------------------------------------------------
# 5. 성적 등록 (ttest 삽입)
# ---------------------------------------------------------
@app.get("/insert")
def insert_score(
    uid: str = Query(..., description="교육생 아이디"),
    kor: int = Query(..., description="국어 점수"),
    eng: int = Query(..., description="영어 점수"),
    mat: int = Query(..., description="수학 점수"),
    idx: Optional[str] = Query(None)
):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO ttest (fid, fkor, feng, fmat, fdate) 
                VALUES (%s, %s, %s, %s, NOW())
            """  # 4. 수정됨
            cursor.execute(sql, (uid, kor, eng, mat))
        return {"msg": "success"}
    except Exception as e:
        return {"msg": f"error: {str(e)}"}
    finally:
        conn.close()

# ---------------------------------------------------------
# 6. 성적 수정 (ttest 수정)
# ---------------------------------------------------------
@app.get("/edit")
def edit_score(
    idx: int = Query(..., description="수정할 성적 고유번호(fidx)"),
    kor: int = Query(..., description="국어 점수"),
    eng: int = Query(..., description="영어 점수"),
    mat: int = Query(..., description="수학 점수"),
    uid: Optional[str] = Query(None)
):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                UPDATE ttest 
                SET fkor = %s, feng = %s, fmat = %s, fdate = NOW() 
                WHERE fidx = %s
            """  # 5. 수정됨
            cursor.execute(sql, (kor, eng, mat, idx))
        return {"msg": "success"}
    except Exception as e:
        return {"msg": f"error: {str(e)}"}
    finally:
        conn.close()

# ---------------------------------------------------------
# 7. 성적 삭제 (ttest 삭제)
# ---------------------------------------------------------
@app.get("/delete")
def delete_score(idx: int = Query(..., description="삭제할 성적 고유번호(fidx)")):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = "DELETE FROM ttest WHERE fidx = %s"  # 6. 수정됨
            cursor.execute(sql, (idx,))
        return {"msg": "success"}
    except Exception as e:
        return {"msg": f"error: {str(e)}"}
    finally:
        conn.close()