SELECT i.i_category,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(*) AS sales_cnt,
       (SELECT 10) AS extra_value
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
WHERE i.i_brand = 'amalgexporti #2                                   '
  AND c.c_preferred_cust_flag = 'N'
GROUP BY i.i_category
HAVING SUM(ws.ws_ext_sales_price) > 6208.02
