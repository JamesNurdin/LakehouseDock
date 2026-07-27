WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        wsite.web_site_id,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(wr.wr_net_loss) AS returns_loss,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_birth_country = 'SWITZERLAND'
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity > 1
    GROUP BY cc.cc_call_center_id, wsite.web_site_id
)
SELECT
    cc_call_center_id,
    web_site_id,
    catalog_profit,
    web_profit,
    returns_loss,
    (catalog_profit + web_profit - returns_loss) AS net_contribution,
    (catalog_profit + web_profit) / NULLIF((catalog_sales_amount + web_sales_amount), 0) AS profit_margin
FROM sales_agg
WHERE (catalog_profit + web_profit - returns_loss) > 0
ORDER BY net_contribution DESC
LIMIT 100
