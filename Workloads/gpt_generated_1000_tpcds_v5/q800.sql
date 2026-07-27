WITH agg_cs AS (
    SELECT
        cs_call_center_sk,
        cs_item_sk,
        cs_sold_date_sk,
        cs_ship_date_sk,
        cs_order_number,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity
    FROM catalog_sales
    GROUP BY cs_call_center_sk, cs_item_sk, cs_sold_date_sk, cs_ship_date_sk, cs_order_number
),
base AS (
    SELECT
        d_sold.d_year,
        i.i_category,
        cc.cc_name,
        SUM(agg_cs.total_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt,
        SUM(sr.sr_fee) AS total_return_fee
    FROM agg_cs
    JOIN call_center cc ON agg_cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON agg_cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d_sold ON agg_cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON agg_cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN promotion p ON i.i_item_sk = p.p_item_sk
    JOIN date_dim d_promo_start ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = agg_cs.cs_order_number
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_sales ss ON ss.ss_item_sk = agg_cs.cs_item_sk
                         AND ss.ss_sold_date_sk = agg_cs.cs_sold_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                         AND inv.inv_date_sk = d_sold.d_date_sk
    WHERE EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_fee > 50
          AND sr2.sr_ticket_number = ss.ss_ticket_number
    )
    GROUP BY d_sold.d_year, i.i_category, cc.cc_name
)
SELECT
    d_year,
    i_category,
    cc_name,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY i_category ORDER BY d_year) AS cumulative_sales,
    store_ticket_cnt,
    total_return_fee
FROM base
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
