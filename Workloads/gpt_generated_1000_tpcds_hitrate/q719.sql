WITH
sales_agg AS (
    SELECT
        cs_sold_time_sk,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    WHERE cs_coupon_amt > 1000
      AND cs_ext_wholesale_cost BETWEEN 1000 AND 8000
      AND cs_quantity >= 1
      AND cs_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY cs_sold_time_sk
),
returns_agg AS (
    SELECT
        sr_return_time_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt > 0
      AND sr_fee < 50
      AND sr_store_credit IS NOT NULL
      AND sr_return_ship_cost BETWEEN 0 AND 100
    GROUP BY sr_return_time_sk, sr_reason_sk
),
joined_base AS (
    SELECT
        t.t_time_id,
        t.t_sub_shift,
        t.t_hour,
        t.t_minute,
        t.t_second,
        t.t_meal_time,
        r.r_reason_desc,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(rtn.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_sales, 0) - COALESCE(rtn.total_return_amount, 0) AS net_amount
    FROM sales_agg s
    RIGHT OUTER JOIN time_dim t
        ON s.cs_sold_time_sk = t.t_time_sk
    FULL OUTER JOIN returns_agg rtn
        ON rtn.sr_return_time_sk = t.t_time_sk
    RIGHT OUTER JOIN reason r
        ON rtn.sr_reason_sk = r.r_reason_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND t.t_minute % 5 = 0
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND t.t_meal_time = 'morning'
      AND t.t_second IS NOT NULL
)
SELECT *
FROM (
    SELECT
        DISTINCT
        t_time_id,
        t_sub_shift,
        r_reason_desc,
        total_sales,
        total_return_amount,
        net_amount,
        ROW_NUMBER() OVER (PARTITION BY t_sub_shift ORDER BY net_amount DESC) AS rn
    FROM joined_base
) ranked
WHERE rn <= 5
ORDER BY t_sub_shift, rn
LIMIT 100
