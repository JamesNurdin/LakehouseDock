WITH sampled_customers AS (
    SELECT *
    FROM customer TABLESAMPLE BERNOULLI (10)
),
excluded_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_amount = 0
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity = 0
),
base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_year,
        cd.cd_gender,
        hd.hd_buy_potential,
        p.p_channel_email,
        r.r_reason_desc,
        CASE WHEN cr.cr_return_amount > 100 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN sampled_customers c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    FULL OUTER JOIN promotion p
        ON d.d_date_sk = p.p_start_date_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential IN ('501-1000', '>10000')
        AND (p.p_channel_email = 'Y' OR p.p_channel_email = 'N')
        AND cr.cr_return_amount > 0
        AND cr.cr_order_number NOT IN (SELECT cr_order_number FROM excluded_orders)
),
agg AS (
    SELECT
        d_year,
        hd_buy_potential,
        return_category,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        AVG(cr_return_quantity) AS avg_quantity
    FROM base
    GROUP BY ROLLUP (d_year, hd_buy_potential, return_category)
)
SELECT
    d_year,
    hd_buy_potential,
    return_category,
    total_return_amount,
    cnt_returns,
    avg_quantity,
    ROW_NUMBER() OVER (ORDER BY total_return_amount DESC) AS rn
FROM agg
WHERE total_return_amount > 500
ORDER BY total_return_amount DESC
LIMIT 100
