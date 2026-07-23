WITH inv_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
sales_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS state,
        i.i_item_id AS item_id,
        i.i_category AS category,
        inv_agg.total_qty_on_hand,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS catalog_returns_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_returns_loss
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
        AND cs.cs_bill_customer_sk = c.c_customer_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND i.i_category = 'Electronics'
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND ib.ib_lower_bound >= 50000
        AND cd.cd_education_status = 'Advanced Degree'
        AND hd.hd_vehicle_count >= 2
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        i.i_item_id,
        i.i_category,
        inv_agg.total_qty_on_hand
)
SELECT
    store_id,
    store_name,
    state,
    item_id,
    category,
    total_qty_on_hand,
    store_sales_profit,
    catalog_sales_profit,
    web_sales_profit,
    catalog_returns_loss,
    web_returns_loss,
    (store_sales_profit + catalog_sales_profit + web_sales_profit - catalog_returns_loss - web_returns_loss) AS total_net_profit,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY (store_sales_profit + catalog_sales_profit + web_sales_profit - catalog_returns_loss - web_returns_loss) DESC) AS store_rank_by_state
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
