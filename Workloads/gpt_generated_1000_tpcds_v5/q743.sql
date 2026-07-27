WITH sales_agg AS (
    SELECT
        d.d_year,
        w.web_name,
        CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END AS discount_level,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        AVG(cs.cs_coupon_amt) AS avg_coupon
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND d.d_current_quarter = 'Y'
        AND cs.cs_wholesale_cost > 20
        AND cs.cs_coupon_amt < 500
        AND p.p_channel_radio = 'N'
        AND w.web_country = 'United States'
        AND p.p_discount_active = 'Y'
    GROUP BY
        d.d_year,
        w.web_name,
        CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High' ELSE 'Low' END
    HAVING SUM(cs.cs_net_paid) > 1000
),
ranked AS (
    SELECT
        d_year,
        web_name,
        discount_level,
        total_net_paid,
        sales_cnt,
        avg_coupon,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS net_paid_rank
    FROM sales_agg
)
SELECT
    d_year,
    web_name,
    discount_level,
    total_net_paid,
    sales_cnt,
    avg_coupon,
    net_paid_rank
FROM ranked
WHERE net_paid_rank <= 10
ORDER BY d_year ASC, net_paid_rank ASC
LIMIT 100
