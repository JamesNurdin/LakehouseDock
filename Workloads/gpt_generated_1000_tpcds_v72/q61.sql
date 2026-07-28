WITH
customer_agg AS (
    SELECT
        c.c_customer_id AS entity_id,
        'customer' AS entity_type,
        d.d_year,
        SUM(cs.cs_net_paid) + COALESCE(SUM(ss.ss_net_paid), 0) + COALESCE(SUM(ws.ws_net_paid), 0)
            - COALESCE(SUM(cr.cr_return_amount), 0) - COALESCE(SUM(sr.sr_return_amt), 0) AS net_revenue,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_paid) DESC) AS yearly_rank,
        mq.max_qty_per_item,
        -- include all join keys for later reference if needed
        d.d_date_sk
    FROM catalog_sales cs
    INNER JOIN catalog_page cp                 ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd       ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT  JOIN catalog_returns cr             ON cr.cr_order_number = cs.cs_order_number
                                                  AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT  JOIN store_sales ss                 ON ss.ss_customer_sk = c.c_customer_sk
                                                  AND ss.ss_sold_date_sk = d.d_date_sk
    LEFT  JOIN household_demographics hd2    ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    LEFT  JOIN store_returns sr               ON sr.sr_ticket_number = ss.ss_ticket_number
                                                  AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT  JOIN web_sales ws                  ON ws.ws_bill_customer_sk = c.c_customer_sk
                                                  AND ws.ws_sold_date_sk = d.d_date_sk
    LEFT  JOIN web_page wp                    ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT  JOIN income_band ib                 ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT MAX(cs2.cs_quantity) AS max_qty_per_item
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = cs.cs_item_sk
    ) AS mq
    WHERE cp.cp_type = 'monthly'
      AND p.p_channel_demo = 'N'
      AND d.d_year BETWEEN 1999 AND 2001
      AND ib.ib_upper_bound < 80000
    GROUP BY c.c_customer_id, d.d_year, mq.max_qty_per_item, d.d_date_sk
),

promo_agg AS (
    SELECT
        p.p_promo_id AS entity_id,
        'promotion' AS entity_type,
        d.d_year,
        SUM(cs.cs_net_paid) AS net_revenue,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        d.d_date_sk
    FROM catalog_sales cs
    INNER JOIN promotion p                 ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN date_dim d                  ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN customer c                  ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd   ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT  JOIN income_band ib              ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_type = 'monthly'
      AND p.p_channel_demo = 'N'
      AND d.d_year BETWEEN 1999 AND 2001
      AND ib.ib_upper_bound < 80000
    GROUP BY p.p_promo_id, d.d_year, d.d_date_sk
)
SELECT *
FROM (
    SELECT
        entity_type,
        entity_id,
        d_year,
        net_revenue,
        order_cnt,
        yearly_rank,
        max_qty_per_item
    FROM customer_agg
    WHERE net_revenue > (
        SELECT AVG(net_revenue) FROM customer_agg
    )

    UNION ALL

    SELECT
        entity_type,
        entity_id,
        d_year,
        net_revenue,
        order_cnt,
        NULL AS yearly_rank,
        NULL AS max_qty_per_item
    FROM promo_agg
) AS combined
ORDER BY net_revenue DESC
LIMIT 100
