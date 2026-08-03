WITH cr_agg AS (
    SELECT
        cr.cr_catalog_page_sk,
        cr.cr_returned_time_sk,
        COUNT(*) AS cnt_returns,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_return_tax) AS sum_return_tax,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        SUM(CASE WHEN cr.cr_return_amount > 500 THEN cr.cr_return_amount ELSE 0 END) AS sum_high_return_amount
    FROM catalog_returns cr
    WHERE cr.cr_refunded_addr_sk IN (3936083, 2591822)
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount >= 100
    GROUP BY cr.cr_catalog_page_sk, cr.cr_returned_time_sk
)
SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    t.t_hour,
    cr_agg.cnt_returns,
    cr_agg.sum_return_amount,
    cr_agg.sum_return_tax,
    cr_agg.sum_net_loss,
    CASE WHEN cr_agg.sum_net_loss > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM cr_agg
JOIN catalog_page cp
  ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
  ON cr_agg.cr_returned_time_sk = t.t_time_sk
JOIN web_returns wr
  ON t.t_time_sk = wr.wr_returned_time_sk
WHERE cp.cp_department = 'Books'
  AND cp.cp_catalog_page_number BETWEEN 5 AND 20
  AND t.t_hour BETWEEN 9 AND 17
  AND wr.wr_return_ship_cost > 100

UNION DISTINCT

SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_page_number,
    t.t_hour,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_returns,
    SUM(cr.cr_return_amount + wr.wr_return_amt) AS sum_return_amount,
    SUM(cr.cr_return_tax + wr.wr_return_tax) AS sum_return_tax,
    SUM(cr.cr_net_loss + wr.wr_net_loss) AS sum_net_loss,
    CASE WHEN SUM(cr.cr_return_amount) > 2000 THEN 'High' ELSE 'Low' END AS loss_category
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN web_returns wr
  ON wr.wr_returned_time_sk = t.t_time_sk
WHERE cp.cp_type = 'Standard'
  AND cp.cp_catalog_number IN (8, 15)
  AND t.t_meal_time = 'Lunch'
  AND wr.wr_return_ship_cost BETWEEN 100 AND 500
GROUP BY cp.cp_department, cp.cp_type, cp.cp_catalog_page_number, t.t_hour

ORDER BY loss_category DESC, sum_return_amount DESC
LIMIT 100
