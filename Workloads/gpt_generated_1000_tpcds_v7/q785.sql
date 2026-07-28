SELECT
    W.w_warehouse_name AS warehouse_name,
    P.p_promo_name   AS promotion_name,
    R.r_reason_desc  AS return_reason,
    I.i_category      AS item_category,
    COUNT(DISTINCT C.c_customer_sk) AS distinct_customers,
    SUM(CS.cs_net_paid)            AS total_sales,
    SUM(SR.sr_return_amt)          AS total_store_returns,
    SUM(WR.wr_return_amt)          AS total_web_returns,
    AVG(CS.cs_ext_discount_amt)    AS avg_discount_amount,
    MIN(CS.cs_sales_price)         AS min_sales_price,
    MAX(CS.cs_sales_price)         AS max_sales_price
FROM catalog_sales CS
LEFT JOIN catalog_page CP ON CS.cs_catalog_page_sk = CP.cp_catalog_page_sk
LEFT JOIN item I          ON CS.cs_item_sk = I.i_item_sk
LEFT JOIN promotion P     ON CS.cs_promo_sk = P.p_promo_sk
LEFT JOIN warehouse W     ON CS.cs_warehouse_sk = W.w_warehouse_sk
LEFT JOIN inventory INV   ON INV.inv_item_sk = I.i_item_sk
                               AND INV.inv_warehouse_sk = W.w_warehouse_sk
LEFT JOIN customer C     ON CS.cs_bill_customer_sk = C.c_customer_sk
LEFT JOIN store_returns SR ON SR.sr_item_sk = I.i_item_sk
                                 AND SR.sr_customer_sk = C.c_customer_sk
LEFT JOIN reason R        ON SR.sr_reason_sk = R.r_reason_sk
LEFT JOIN web_returns WR  ON WR.wr_item_sk = I.i_item_sk
                                 AND WR.wr_refunded_customer_sk = C.c_customer_sk
WHERE INV.inv_warehouse_sk = 14
  AND P.p_channel_dmail = 'Y'
  AND C.c_email_address LIKE '%@LM674NrE2.org'
GROUP BY
    W.w_warehouse_name,
    P.p_promo_name,
    R.r_reason_desc,
    I.i_category
