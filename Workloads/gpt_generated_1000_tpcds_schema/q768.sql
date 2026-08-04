WITH sales_agg AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_ext_sales_price > 1000
      AND ss.ss_ext_discount_amt BETWEEN 0 AND 500
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cd.cd_education_status = 'College'
      AND ss.ss_quantity > 1
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY ss.ss_ticket_number, ss.ss_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
returns_agg AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_customer_sk,
        c2.c_first_name AS r_first_name,
        c2.c_last_name AS r_last_name,
        cd2.cd_gender AS r_gender,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer c2 ON sr.sr_customer_sk = c2.c_customer_sk
    JOIN customer_demographics cd2 ON sr.sr_cdemo_sk = cd2.cd_demo_sk
    WHERE sr.sr_return_amt_inc_tax > 50
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_tax < 10
      AND cd2.cd_dep_college_count >= 1
      AND c2.c_birth_month IN (1,2,3,4,5,6)
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY sr.sr_ticket_number, sr.sr_customer_sk, c2.c_first_name, c2.c_last_name, cd2.cd_gender
),
full_data AS (
    SELECT
        COALESCE(sa.ss_ticket_number, ra.sr_ticket_number) AS ticket_number,
        COALESCE(sa.ss_customer_sk, ra.sr_customer_sk) AS customer_sk,
        COALESCE(sa.c_first_name, ra.r_first_name) AS first_name,
        COALESCE(sa.c_last_name, ra.r_last_name) AS last_name,
        COALESCE(sa.cd_gender, ra.r_gender) AS gender,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(ra.total_return_amt, 0) AS total_return_amt,
        (COALESCE(sa.total_sales, 0) - COALESCE(ra.total_return_amt, 0)) AS net_amount,
        COALESCE(sa.sales_cnt, 0) AS sales_cnt,
        COALESCE(ra.return_cnt, 0) AS return_cnt
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.ss_ticket_number = ra.sr_ticket_number
)
SELECT ticket_number,
       customer_sk,
       first_name,
       last_name,
       gender,
       total_sales,
       total_return_amt,
       net_amount,
       sales_cnt,
       return_cnt
FROM (
    SELECT *
    FROM full_data fd
    WHERE net_amount > 0
      AND total_sales > 500
      AND total_return_amt < 1000
      AND sales_cnt >= 1
      AND return_cnt >= 0
      AND EXISTS (
          SELECT 1
          FROM store_returns sr3
          WHERE sr3.sr_ticket_number = fd.ticket_number
            AND sr3.sr_return_amt_inc_tax > 200
      )
) AS filtered
EXCEPT
SELECT ticket_number,
       customer_sk,
       first_name,
       last_name,
       gender,
       total_sales,
       total_return_amt,
       net_amount,
       sales_cnt,
       return_cnt
FROM (
    SELECT *
    FROM full_data fd2
    WHERE fd2.total_return_amt = 0
) AS zero_returns
ORDER BY net_amount DESC
LIMIT 100
