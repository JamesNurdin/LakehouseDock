WITH sales_base AS (
    SELECT
        c_bill.c_customer_sk AS cust_sk,
        c_bill.c_preferred_cust_flag AS pref_flag,
        td.t_hour,
        p.p_channel_radio,
        cs.cs_net_paid AS amount
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c_bill
        ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    WHERE p.p_cost > 500
      AND td.t_am_pm = 'PM'
      AND c_bill.c_birth_year BETWEEN 1960 AND 1990
),
returns_base AS (
    SELECT
        c_refunded.c_customer_sk AS cust_sk,
        NULL AS pref_flag,
        td_ret.t_hour,
        NULL AS p_channel_radio,
        -wr.wr_net_loss AS amount
    FROM web_returns wr
    JOIN time_dim td_ret
        ON wr.wr_returned_time_sk = td_ret.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_page
        ON wp.wp_customer_sk = c_page.c_customer_sk
    JOIN customer c_refunded
        ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    WHERE td_ret.t_am_pm = 'AM'
      AND wr.wr_return_quantity > 1
      AND wp.wp_type = 'detail'
),
combined AS (
    SELECT cust_sk, pref_flag, t_hour, p_channel_radio, amount
    FROM sales_base
    UNION ALL
    SELECT cust_sk, pref_flag, t_hour, p_channel_radio, amount
    FROM returns_base
),
agg AS (
    SELECT
        cust_sk,
        pref_flag,
        t_hour,
        p_channel_radio,
        SUM(amount) AS total_amount,
        COUNT(*) AS row_cnt,
        ROW_NUMBER() OVER (PARTITION BY p_channel_radio ORDER BY SUM(amount) DESC) AS rn
    FROM combined
    GROUP BY GROUPING SETS (
        (cust_sk, pref_flag, t_hour, p_channel_radio),
        (cust_sk, pref_flag, p_channel_radio),
        (t_hour, p_channel_radio),
        (p_channel_radio),
        ()
    )
),
final AS (
    SELECT *
    FROM agg
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN customer c2
            ON wr2.wr_refunded_customer_sk = c2.c_customer_sk
        WHERE c2.c_customer_sk = agg.cust_sk
          AND wr2.wr_return_quantity > 5
    )
)
SELECT
    cust_sk,
    pref_flag,
    t_hour,
    p_channel_radio,
    total_amount,
    row_cnt,
    rn
FROM final
WHERE total_amount > 1000
ORDER BY total_amount DESC, rn
LIMIT 100
