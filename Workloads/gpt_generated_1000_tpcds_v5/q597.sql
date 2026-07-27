WITH sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_promo_sk AS promo_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE
        cs.cs_quantity > 1
        AND t.t_hour BETWEEN 8 AND 20
        AND cs.cs_ext_discount_amt < 1000
        AND cs.cs_ext_sales_price > 0
        AND cs.cs_net_paid_inc_tax > 0
    GROUP BY cs.cs_bill_customer_sk, cs.cs_promo_sk
),
filtered AS (
    SELECT
        s.cust_sk,
        s.promo_sk,
        s.total_profit,
        s.sales_cnt,
        c.c_customer_id,
        c.c_customer_sk,
        p.p_promo_name,
        ROW_NUMBER() OVER (PARTITION BY s.promo_sk ORDER BY s.total_profit DESC) AS rn
    FROM sales_agg s
    JOIN customer c ON s.cust_sk = c.c_customer_sk
    JOIN promotion p ON s.promo_sk = p.p_promo_sk
    WHERE
        p.p_purpose = 'Discount'
        AND p.p_channel_radio = 'N'
        AND p.p_response_target > 10
        AND c.c_salutation IN ('Mr.', 'Ms.', 'Dr.')
        AND c.c_birth_year BETWEEN 1950 AND 2000
        AND c.c_customer_sk IN (
            SELECT DISTINCT sr.sr_customer_sk
            FROM store_returns sr
            WHERE sr.sr_return_amt_inc_tax > 500
        )
        AND EXISTS (
            SELECT 1
            FROM store_returns sr
            JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
            WHERE sr.sr_customer_sk = c.c_customer_sk
              AND t_ret.t_hour BETWEEN 9 AND 17
        )
)
SELECT DISTINCT
    f.c_customer_id,
    f.p_promo_name,
    ROUND(f.total_profit, 2) AS total_profit,
    f.sales_cnt,
    (
        SELECT SUM(sr2.sr_return_amt_inc_tax)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = f.c_customer_sk
    ) AS total_return_amount
FROM filtered f
WHERE f.rn = 1
ORDER BY total_profit DESC
LIMIT 100
