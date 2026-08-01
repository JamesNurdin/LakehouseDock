WITH
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
        WHERE cs_quantity > 1
          AND cs_wholesale_cost > 5.0
          AND cs_list_price BETWEEN 10 AND 1000
          AND cs_ship_mode_sk IS NOT NULL
    ),
    sales_agg AS (
        SELECT
            ss.cs_bill_customer_sk   AS customer_sk,
            ss.cs_sold_time_sk       AS time_sk,
            ss.cs_promo_sk           AS promo_sk,
            SUM(ss.cs_ext_sales_price) AS total_sales,
            SUM(ss.cs_net_profit)       AS total_profit,
            COUNT(DISTINCT ss.cs_order_number) AS distinct_orders,
            CASE WHEN SUM(ss.cs_ext_sales_price) > 10000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
        FROM sampled_sales ss
        GROUP BY ss.cs_bill_customer_sk, ss.cs_sold_time_sk, ss.cs_promo_sk
    ),
    returns_agg AS (
        SELECT
            sr.sr_customer_sk AS customer_sk,
            sr.sr_return_time_sk AS time_sk,
            SUM(sr.sr_return_amt)   AS total_return_amt,
            SUM(sr.sr_net_loss)     AS total_net_loss,
            COUNT(*)                AS return_cnt
        FROM store_returns sr
        WHERE sr.sr_return_quantity > 0
          AND sr.sr_return_ship_cost > 0
          AND sr.sr_refunded_cash < 500
          AND sr.sr_fee IS NOT NULL
        GROUP BY sr.sr_customer_sk, sr.sr_return_time_sk
    ),
    union_data AS (
        SELECT
            s.customer_sk,
            s.time_sk,
            s.promo_sk,
            s.total_sales      AS amount,
            s.total_profit     AS profit,
            'sale'   AS src
        FROM sales_agg s
        UNION
        SELECT
            r.customer_sk,
            r.time_sk,
            NULL               AS promo_sk,
            r.total_return_amt AS amount,
            -r.total_net_loss  AS profit,
            'return' AS src
        FROM returns_agg r
    ),
    filtered_union AS (
        SELECT *
        FROM union_data ud
        WHERE ud.amount > 0
          AND ud.profit IS NOT NULL
    )
SELECT DISTINCT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    t.t_shift,
    ud.src,
    ud.amount,
    ud.profit,
    CASE WHEN ud.src = 'sale' THEN 'Sales' ELSE 'Returns' END AS type_label,
    CASE 
        WHEN p.p_channel_email = 'N' AND p.p_channel_press = 'N' THEN 'NoDigital'
        ELSE 'HasDigital'
    END AS promo_channel_type,
    q.qty_val,
    SUM(ud.amount) OVER (PARTITION BY c.c_customer_sk ORDER BY t.t_hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_amount,
    RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ud.amount DESC) AS sales_rank
FROM filtered_union ud
FULL OUTER JOIN customer c
    ON c.c_customer_sk = ud.customer_sk
LEFT JOIN time_dim t
    ON t.t_time_sk = ud.time_sk
LEFT JOIN promotion p
    ON p.p_promo_sk = ud.promo_sk
CROSS JOIN UNNEST(ARRAY[ud.amount, ud.profit]) AS q(qty_val)
WHERE EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = ud.promo_sk
          AND p2.p_discount_active = 'Y'
    )
  AND c.c_birth_year BETWEEN 1950 AND 1990
  AND c.c_birth_month IN (1,2,3,4,5)
  AND t.t_shift = 'first'
  AND t.t_am_pm = 'PM'
  AND t.t_hour BETWEEN 8 AND 20
  AND t.t_meal_time = 'dinner'
  AND ud.amount > 100
ORDER BY ud.amount DESC
LIMIT 100
