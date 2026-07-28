WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        i.i_item_id,
        i.i_product_name,
        i.i_units,
        i.i_manager_id,
        p.p_promo_name,
        sm.sm_type AS ship_type,
        w.w_state,
        t.t_hour,
        cd_bill.cd_credit_rating,
        ca_bill.ca_state AS bill_state,
        sr.sr_return_quantity,
        r_sr.r_reason_desc AS store_return_reason,
        wr.wr_return_quantity,
        r_wr.r_reason_desc AS web_return_reason,
        ws.ws_quantity AS web_quantity,
        wsite.web_name,
        inv.inv_quantity_on_hand,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
                         AND sr.sr_return_time_sk = t.t_time_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk = ca_sr.ca_address_sk
    WHERE cd_bill.cd_credit_rating = 'Good'
      AND i.i_units = 'Each'
      AND t.t_hour BETWEEN 9 AND 17
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = cs.cs_item_sk
            AND sr2.sr_return_quantity > 0
      )
)
SELECT
    i_item_id,
    i_product_name,
    profit_flag,
    cs_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY cs_net_profit DESC) AS profit_rank,
    RANK() OVER (PARTITION BY i_item_id ORDER BY cs_net_profit DESC) AS profit_dense_rank,
    SUM(cs_ext_sales_price) OVER (
        PARTITION BY i_item_id
        ORDER BY cs_sold_date_sk
        ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
    ) AS rolling_30day_sales
FROM joined
ORDER BY cs_net_profit DESC
LIMIT 100
