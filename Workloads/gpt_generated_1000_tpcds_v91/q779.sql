WITH
    sales_morning AS (
        SELECT
            ss.ss_item_sk AS item_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales_morning
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 12
        GROUP BY ss.ss_item_sk
    ),
    returns_morning AS (
        SELECT
            sr.sr_item_sk AS item_sk,
            SUM(sr.sr_return_amt) AS total_returns_morning
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 12
        GROUP BY sr.sr_item_sk
    ),
    full_morning AS (
        SELECT
            COALESCE(s.item_sk, r.item_sk) AS item_sk,
            s.total_sales_morning,
            r.total_returns_morning
        FROM sales_morning s
        FULL OUTER JOIN returns_morning r
            ON s.item_sk = r.item_sk
    ),
    sales_afternoon AS (
        SELECT
            ss.ss_item_sk AS item_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales_afternoon
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 13 AND 17
        GROUP BY ss.ss_item_sk
    ),
    returns_afternoon AS (
        SELECT
            sr.sr_item_sk AS item_sk,
            SUM(sr.sr_return_amt) AS total_returns_afternoon
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 13 AND 17
        GROUP BY sr.sr_item_sk
    ),
    full_afternoon AS (
        SELECT
            COALESCE(s.item_sk, r.item_sk) AS item_sk,
            s.total_sales_afternoon,
            r.total_returns_afternoon
        FROM sales_afternoon s
        FULL OUTER JOIN returns_afternoon r
            ON s.item_sk = r.item_sk
    ),
    combined AS (
        SELECT
            i.i_item_id,
            i.i_product_name,
            fm.total_sales_morning,
            fm.total_returns_morning,
            NULL AS total_sales_afternoon,
            NULL AS total_returns_afternoon
        FROM full_morning fm
        JOIN item i ON fm.item_sk = i.i_item_sk
        UNION ALL
        SELECT
            i.i_item_id,
            i.i_product_name,
            NULL,
            NULL,
            fa.total_sales_afternoon,
            fa.total_returns_afternoon
        FROM full_afternoon fa
        JOIN item i ON fa.item_sk = i.i_item_sk
    )
SELECT
    c.i_item_id,
    c.i_product_name,
    COALESCE(c.total_sales_morning, 0) + COALESCE(c.total_sales_afternoon, 0) AS total_sales,
    COALESCE(c.total_returns_morning, 0) + COALESCE(c.total_returns_afternoon, 0) AS total_returns,
    (SELECT AVG(i_current_price) FROM item) AS avg_item_price,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM customer cu
            JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
            WHERE cu.c_preferred_cust_flag = 'Y'
              AND cd.cd_gender = 'F'
            LIMIT 1
        ) THEN 'Preferred female exists'
        ELSE 'No preferred female'
    END AS female_preferred_flag
FROM combined c
ORDER BY total_sales DESC
LIMIT 20
