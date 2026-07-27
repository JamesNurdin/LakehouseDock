WITH agg_per_store_year AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(cr.cr_fee) AS total_return_fee,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(DISTINCT cs.cs_order_number) AS orders_count
    FROM date_dim d
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
        AND cr.cr_reason_sk = r.r_reason_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_radio = 'N'
      AND s.s_state = 'CA'
      AND w.w_state = 'CA'
      AND cs.cs_quantity > 1
    GROUP BY s.s_store_name, d.d_year
)
SELECT
    store_name,
    year,
    total_sales_profit,
    total_return_loss
FROM agg_per_store_year
WHERE total_sales_profit > (
    SELECT AVG(total_sales_profit) FROM agg_per_store_year
)
ORDER BY total_sales_profit DESC
LIMIT 100
