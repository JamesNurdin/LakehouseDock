WITH
    sales_agg AS (
        SELECT
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_ship_date_sk,
            SUM(cs_ext_sales_price) AS total_sales,
            SUM(cs_quantity) AS total_qty,
            SUM(cs_net_profit) AS total_profit
        FROM catalog_sales
        WHERE cs_ship_date_sk BETWEEN 2450820 AND 2450900
        GROUP BY cs_bill_customer_sk, cs_bill_cdemo_sk, cs_ship_date_sk
    ),
    returns_agg AS (
        SELECT
            sr_customer_sk,
            sr_cdemo_sk,
            sr_reason_sk,
            SUM(sr_return_amt) AS total_return_amt,
            SUM(sr_return_quantity) AS total_return_qty
        FROM store_returns
        WHERE sr_returned_date_sk BETWEEN 2450820 AND 2450900
        GROUP BY sr_customer_sk, sr_cdemo_sk, sr_reason_sk
    ),
    subq1 AS (
        SELECT
            c.c_customer_sk,
            c.c_email_address,
            cd.cd_gender,
            r.r_reason_desc,
            s.total_sales,
            r2.total_return_amt
        FROM sales_agg s
        JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN returns_agg r2 ON sr.sr_customer_sk = r2.sr_customer_sk AND sr.sr_cdemo_sk = r2.sr_cdemo_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer c_ship ON s.cs_bill_customer_sk = c_ship.c_customer_sk
        JOIN customer_demographics cd_ship ON s.cs_bill_cdemo_sk = cd_ship.cd_demo_sk
        WHERE c.c_preferred_cust_flag = 'Y'
    ),
    subq2 AS (
        SELECT
            c.c_customer_sk,
            c.c_email_address,
            cd.cd_gender,
            r.r_reason_desc,
            s.total_sales,
            r2.total_return_amt
        FROM sales_agg s
        JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON s.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN returns_agg r2 ON sr.sr_customer_sk = r2.sr_customer_sk AND sr.sr_cdemo_sk = r2.sr_cdemo_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer c_ship2 ON s.cs_bill_customer_sk = c_ship2.c_customer_sk
        JOIN customer_demographics cd_ship2 ON s.cs_bill_cdemo_sk = cd_ship2.cd_demo_sk
        WHERE c.c_birth_country = 'TOGO'
    ),
    intersect_set AS (
        SELECT * FROM subq1
        INTERSECT
        SELECT * FROM subq2
    ),
    union_set AS (
        SELECT
            i.c_customer_sk,
            i.c_email_address,
            i.cd_gender,
            i.r_reason_desc,
            i.total_sales,
            i.total_return_amt,
            ROW_NUMBER() OVER (PARTITION BY i.c_customer_sk ORDER BY i.total_sales DESC) AS rk
        FROM intersect_set i
        WHERE i.total_sales > (SELECT MAX(total_sales) FROM sales_agg) * 0.5
        UNION DISTINCT
        SELECT
            i.c_customer_sk,
            i.c_email_address,
            i.cd_gender,
            i.r_reason_desc,
            i.total_sales,
            i.total_return_amt,
            ROW_NUMBER() OVER (PARTITION BY i.c_customer_sk ORDER BY i.total_sales ASC) AS rk
        FROM intersect_set i
        WHERE i.total_return_amt < (SELECT MIN(total_return_amt) FROM returns_agg) * 2
    ),
    final_set AS (
        SELECT * FROM union_set WHERE rk <= 3
    )
SELECT
    f.c_customer_sk,
    f.c_email_address,
    f.cd_gender,
    f.r_reason_desc,
    f.total_sales,
    f.total_return_amt,
    f.rk
FROM final_set f
ORDER BY f.total_sales DESC
LIMIT 100
