WITH sr_agg AS (
    SELECT
        sr_reason_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk IS NOT NULL
    GROUP BY sr_reason_sk, sr_returned_date_sk
)
SELECT
    d_ret.d_year AS return_year,
    r.r_reason_desc,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    SUM(sr_agg.total_loss) AS store_total_loss,
    SUM(ws.ws_net_profit) AS web_sales_profit,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    (
        SELECT SUM(cs.cs_ext_sales_price)
        FROM catalog_sales cs
        WHERE cs.cs_item_sk = i.i_item_sk
          AND cs.cs_sold_date_sk = d_ret.d_date_sk
    ) AS catalog_sales_total_price
FROM sr_agg
JOIN date_dim d_ret
    ON sr_agg.sr_returned_date_sk = d_ret.d_date_sk
JOIN reason r
    ON sr_agg.sr_reason_sk = r.r_reason_sk
-- web returns and related dimensions
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
-- web_sales supporting dimensions
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN time_dim t_ws
    ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca_ws_bill
    ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
    ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
-- catalog_sales and its dimensions (re‑using item i)
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN promotion p_cs
    ON cs.cs_promo_sk = p_cs.p_promo_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_cs_bill
    ON cs.cs_bill_addr_sk = ca_cs_bill.ca_address_sk
JOIN customer_address ca_cs_ship
    ON cs.cs_ship_addr_sk = ca_cs_ship.ca_address_sk
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_order_number = ws.ws_order_number
)
GROUP BY
    d_ret.d_year,
    r.r_reason_desc,
    i.i_product_name,
    p.p_promo_name,
    cc.cc_name,
    sm.sm_type,
    d_ret.d_date_sk,
    i.i_item_sk
LIMIT 100
