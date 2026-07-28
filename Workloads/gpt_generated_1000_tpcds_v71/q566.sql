WITH agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(cs.cs_net_paid) AS total_catalog_paid,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND t.t_meal_time = 'lunch'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND ss.ss_quantity > 1
    GROUP BY p.p_promo_id, d.d_year
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    promo_id,
    year,
    total_store_profit,
    total_catalog_paid,
    (total_store_profit + total_catalog_paid) / NULLIF((total_store_return_loss + total_web_return_loss), 0) AS profit_to_loss_ratio,
    avg_inventory_qty
FROM agg
WHERE EXISTS (
    SELECT 1
    FROM tpcds.promotion p2
    WHERE p2.p_promo_id = agg.promo_id
      AND p2.p_purpose = 'Unknown'
)
ORDER BY profit_to_loss_ratio DESC
LIMIT 100
