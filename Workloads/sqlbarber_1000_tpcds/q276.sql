SELECT sr.sr_store_sk, SUM(ss.ss_net_paid) AS total_sales FROM store_returns sr JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk WHERE sr.sr_returned_date_sk = 2451329 GROUP BY sr.sr_store_sk
