SELECT
  i.i_category,
  SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_amount ELSE 0 END) AS total_catalog_return_amount,
  SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_return_amt ELSE 0 END) AS total_store_return_amount,
  SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_web_sales,
  CASE WHEN SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) = 0 THEN NULL
       ELSE (SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_amount ELSE 0 END) +
             SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_return_amt ELSE 0 END)) /
            SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END)
  END AS return_to_sales_ratio,
  RANK() OVER (ORDER BY
    CASE WHEN SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) = 0 THEN 0
         ELSE (SUM(CASE WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_amount ELSE 0 END) +
               SUM(CASE WHEN sr.sr_item_sk IS NOT NULL THEN sr.sr_return_amt ELSE 0 END)) /
              SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END)
    END DESC) AS ratio_rank
FROM item i
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_return_quantity > 0
LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_quantity > 0
LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_quantity > 0
WHERE i.i_category IS NOT NULL
GROUP BY i.i_category
HAVING SUM(CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) > 1000
ORDER BY ratio_rank
LIMIT 5
