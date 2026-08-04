WITH sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_order_number,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_ship_cdemo_sk,
        SUM(ws.ws_net_profit)        AS total_profit,
        SUM(ws.ws_quantity)          AS total_quantity
    FROM tpcds.web_sales ws
    TABLESAMPLE BERNOULLI (5)
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450835
      AND ws.ws_quantity > 1
    GROUP BY
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_order_number,
        ws.ws_bill_addr_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_ship_addr_sk,
        ws.ws_ship_cdemo_sk
)
SELECT
    ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS row_num,
    agg.ws_item_sk,
    i.i_product_name,
    agg.total_profit,
    agg.total_quantity,
    td.t_hour,
    ca_bill.ca_county                     AS bill_county,
    cd_bill.cd_gender                     AS bill_gender,
    s.s_store_name,
    p.p_promo_name,
    inv.inv_quantity_on_hand,
    cr.cr_return_amount,
    wr.wr_return_amt,
    sr.sr_return_amt,
    reason_sr.r_reason_desc               AS store_return_reason,
    reason_cr.r_reason_desc               AS catalog_return_reason,
    reason_wr.r_reason_desc               AS web_return_reason,
    cc.cc_name                            AS call_center_name,
    cp.cp_description                     AS catalog_page_desc
FROM sales_agg agg
JOIN tpcds.item i
    ON agg.ws_item_sk = i.i_item_sk
JOIN tpcds.time_dim td
    ON agg.ws_sold_time_sk = td.t_time_sk
JOIN tpcds.promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
LEFT JOIN tpcds.customer_address ca_bill
    ON agg.ws_bill_addr_sk = ca_bill.ca_address_sk
LEFT JOIN tpcds.customer_address ca_ship
    ON agg.ws_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN tpcds.customer_demographics cd_bill
    ON agg.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN tpcds.customer_demographics cd_ship
    ON agg.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
-- Store Returns and related dimensions
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN tpcds.reason reason_sr
    ON sr.sr_reason_sk = reason_sr.r_reason_sk
-- Catalog Returns and related dimensions
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
LEFT JOIN tpcds.reason reason_cr
    ON cr.cr_reason_sk = reason_cr.r_reason_sk
LEFT JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
-- Web Returns and related dimensions
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_order_number = agg.ws_order_number
   AND wr.wr_item_sk = agg.ws_item_sk
LEFT JOIN tpcds.reason reason_wr
    ON wr.wr_reason_sk = reason_wr.r_reason_sk
WHERE
    ca_bill.ca_county = 'Richland County'
    AND i.i_brand = 'Brand#45'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
    AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_return_quantity > 0
    )
ORDER BY agg.total_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
