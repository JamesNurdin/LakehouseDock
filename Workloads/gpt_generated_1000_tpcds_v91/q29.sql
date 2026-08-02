WITH
sr_agg AS (
    SELECT
        sr_customer_sk,
        sr_returned_date_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_amt > 100
    GROUP BY sr_customer_sk, sr_returned_date_sk
),
intersected_customers AS (
    SELECT sr_customer_sk AS c_customer_sk
    FROM sr_agg
    WHERE total_return_amt > 500
    INTERSECT
    SELECT ws_bill_customer_sk AS c_customer_sk
    FROM web_sales
    WHERE ws_net_paid > 1000
)
SELECT
    c.c_customer_id,
    d_ret.d_year AS return_year,
    d_sold.d_year AS sale_year,
    sr_agg.total_return_amt,
    ws.ws_net_paid AS sale_amount,
    p.p_promo_name,
    ROW_NUMBER() OVER (
        PARTITION BY c.c_customer_id
        ORDER BY (sr_agg.total_return_amt - ws.ws_net_paid) DESC
    ) AS net_contrib_rank
FROM intersected_customers ic
JOIN customer c ON ic.c_customer_sk = c.c_customer_sk
JOIN sr_agg ON sr_agg.sr_customer_sk = c.c_customer_sk
JOIN date_dim d_ret ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE
    c.c_birth_country IN ('JAPAN', 'BARBADOS')
    AND d_ret.d_year = 2002
    AND p.p_discount_active = 'Y'
    AND ws.ws_net_paid > 0
    AND c.c_current_hdemo_sk IN (6247, 1461)
ORDER BY net_contrib_rank
LIMIT 100
