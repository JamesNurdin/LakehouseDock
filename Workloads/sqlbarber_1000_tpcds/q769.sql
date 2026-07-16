SELECT i.i_category, SUM(wr.wr_return_amt) AS total_return FROM web_returns wr JOIN item i ON wr.wr_item_sk = i.i_item_sk WHERE i.i_brand_id = 10007001 GROUP BY i.i_category
