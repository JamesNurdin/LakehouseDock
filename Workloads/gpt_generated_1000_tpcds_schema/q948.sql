/* goal: Identify customers with significant store returns or web sales, filtered by specific reasons, promotional activity and household buying potential, using a sampled customer set and combining results via UNION */
WITH sampled_customers AS (
    SELECT
        c_customer_sk,
        c_customer_id,
        c_current_cdemo_sk,
        c_current_hdemo_sk
    FROM
        customer
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    sc.c_customer_id      AS customer_id,
    'store_return'        AS source,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_amount
FROM
    sampled_customers sc
    FULL OUTER JOIN store_returns sr
        ON sr.sr_customer_sk = sc.c_customer_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE
    r.r_reason_id = 'AAAAAAAAMAAAAAAA'
    AND hd.hd_buy_potential = '5001-10000'
GROUP BY
    sc.c_customer_id,
    'store_return'
HAVING
    COALESCE(SUM(sr.sr_return_amt), 0) > 100

UNION

SELECT
    sc.c_customer_id      AS customer_id,
    'web_sales'           AS source,
    COALESCE(SUM(ws.ws_net_paid), 0) AS total_amount
FROM
    sampled_customers sc
    FULL OUTER JOIN web_sales ws
        ON ws.ws_bill_customer_sk = sc.c_customer_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE
    p.p_discount_active = 'Y'
    AND hd.hd_buy_potential = '1001-5000'
    AND sc.c_current_cdemo_sk IN (
        SELECT cd_demo_sk
        FROM customer_demographics
        WHERE cd_credit_rating = 'Good'
    )
GROUP BY
    sc.c_customer_id,
    'web_sales'
HAVING
    COALESCE(SUM(ws.ws_net_paid), 0) > 200

LIMIT 100
