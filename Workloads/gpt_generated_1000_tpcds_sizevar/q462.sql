WITH sales_agg AS (
    SELECT
        s.s_store_name AS store_name,
        cd.cd_gender AS gender,
        ss.ss_sold_date_sk AS sold_date_sk,
        sum(ss.ss_ext_sales_price) AS total_amount,
        l.avg_qty,
        (SELECT max(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_band
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT avg(ss2.ss_quantity) AS avg_qty
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
          AND ss2.ss_sold_date_sk = ss.ss_sold_date_sk
    ) l
    WHERE s.s_state = 'CA'
      AND ib.ib_upper_bound > 50000
    GROUP BY s.s_store_name, cd.cd_gender, ss.ss_sold_date_sk, l.avg_qty
    HAVING sum(ss.ss_ext_sales_price) > 1000
),
returns_agg AS (
    SELECT
        CAST('Web Return' AS varchar) AS store_name,
        cd.cd_gender AS gender,
        wr.wr_returned_date_sk AS sold_date_sk,
        sum(wr.wr_return_amt) AS total_amount,
        l.avg_qty,
        (SELECT max(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_band
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_returning_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT avg(wr2.wr_return_quantity) AS avg_qty
        FROM web_returns wr2
        WHERE wr2.wr_returning_customer_sk = wr.wr_returning_customer_sk
          AND wr2.wr_returned_date_sk = wr.wr_returned_date_sk
    ) l
    WHERE ib.ib_lower_bound < 30000
    GROUP BY cd.cd_gender, wr.wr_returned_date_sk, l.avg_qty
    HAVING sum(wr.wr_return_amt) > 500
)
SELECT
    u.store_name,
    u.gender,
    u.total_amount,
    sum(u.total_amount) OVER (PARTITION BY u.store_name ORDER BY u.sold_date_sk ROWS UNBOUNDED PRECEDING) AS running_total,
    u.avg_qty,
    u.max_income_band
FROM (
    SELECT store_name, gender, sold_date_sk, total_amount, avg_qty, max_income_band FROM sales_agg
    UNION
    SELECT store_name, gender, sold_date_sk, total_amount, avg_qty, max_income_band FROM returns_agg
) u
ORDER BY u.store_name, u.gender, u.total_amount DESC
LIMIT 100
