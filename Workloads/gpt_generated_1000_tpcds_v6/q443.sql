WITH catalog_data AS (
    SELECT cr_returned_time_sk,
           cr_refunded_customer_sk,
           cr_returning_customer_sk,
           cr_call_center_sk,
           cr_catalog_page_sk,
           cr_return_quantity,
           cr_return_amount,
           cr_net_loss
    FROM catalog_returns
    WHERE cr_returned_date_sk = 2450992
      AND cr_return_amount > 100
      AND cr_return_quantity >= 2
),
store_data AS (
    SELECT sr_return_time_sk,
           sr_customer_sk,
           sr_return_quantity,
           sr_return_amt,
           sr_net_loss
    FROM store_returns
    WHERE sr_return_quantity > 1
),
web_data AS (
    SELECT wr_returned_time_sk,
           wr_refunded_customer_sk,
           wr_returning_customer_sk,
           wr_return_quantity,
           wr_return_amt,
           wr_net_loss
    FROM web_returns
    WHERE wr_return_amt > 50
),
joined AS (
    SELECT cc.cc_name,
           td.t_sub_shift,
           c.c_customer_id,
           cr.cr_return_amount,
           cr.cr_net_loss AS catalog_net_loss,
           sr.sr_return_amt,
           sr.sr_net_loss AS store_net_loss,
           wr.wr_return_amt,
           wr.wr_net_loss AS web_net_loss,
           cp.cp_type
    FROM catalog_data cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN store_data sr ON sr.sr_return_time_sk = td.t_time_sk AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN web_data wr ON wr.wr_returned_time_sk = td.t_time_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE cc.cc_state = 'CA'
      AND c.c_preferred_cust_flag = 'Y'
      AND td.t_sub_shift = 'morning'
      AND cp.cp_type = 'A'
)
SELECT
    cc_name,
    t_sub_shift,
    COUNT(DISTINCT c_customer_id) AS distinct_customers,
    SUM(catalog_net_loss + COALESCE(store_net_loss, 0) + COALESCE(web_net_loss, 0)) AS total_net_loss,
    AVG(CASE WHEN cr_return_amount > 200 THEN cr_return_amount END) AS avg_large_catalog_return,
    (SELECT AVG(cr_net_loss) FROM catalog_returns WHERE cr_returned_date_sk = 2450992) AS overall_avg_catalog_loss
FROM joined
GROUP BY cc_name, t_sub_shift
ORDER BY total_net_loss DESC, distinct_customers DESC
LIMIT 100
