WITH high_income_hd AS (
    SELECT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 80000
)
SELECT
    combined.c_customer_id,
    combined.d_year,
    combined.total_net_paid,
    combined.channel,
    combined.avg_year_net_paid
FROM (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        'Catalog' AS channel,
        (
            SELECT AVG(cs_inner.cs_net_paid)
            FROM catalog_sales cs_inner
            JOIN date_dim d_inner ON cs_inner.cs_sold_date_sk = d_inner.d_date_sk
            WHERE d_inner.d_year = 2001
        ) AS avg_year_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN high_income_hd hi ON cs.cs_bill_hdemo_sk = hi.hd_demo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY c.c_customer_id, d.d_year
    UNION ALL
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_net_paid,
        'Web' AS channel,
        (
            SELECT AVG(ws_inner.ws_net_paid)
            FROM web_sales ws_inner
            JOIN date_dim d_inner ON ws_inner.ws_sold_date_sk = d_inner.d_date_sk
            WHERE d_inner.d_year = 2001
        ) AS avg_year_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN high_income_hd hi ON ws.ws_bill_hdemo_sk = hi.hd_demo_sk
    WHERE d.d_year = 2001
    GROUP BY c.c_customer_id, d.d_year
) combined
ORDER BY combined.total_net_paid DESC
LIMIT 100
