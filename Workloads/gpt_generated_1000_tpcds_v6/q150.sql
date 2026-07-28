WITH joined_all AS (
  SELECT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_cdemo_sk,
    ss.ss_hdemo_sk,
    ss.ss_store_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_education_status,
    hd.hd_buy_potential,
    s.s_store_id,
    s.s_state,
    ts.t_hour,
    ts.t_am_pm,
    wp.wp_autogen_flag,
    wp.wp_link_count,
    inv.inv_quantity_on_hand,
    wr.wr_return_quantity,
    wr.wr_net_loss
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN time_dim ts ON ss.ss_sold_time_sk = ts.t_time_sk
  JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
  JOIN time_dim tw ON wr.wr_returned_time_sk = tw.t_time_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  WHERE i.i_brand = 'Brand#45'                         -- predicate 1
    AND s.s_state = 'CA'                               -- predicate 2
    AND cd.cd_gender = 'M'                             -- predicate 3
    AND hd.hd_buy_potential = '5000-10000'             -- predicate 4
    AND wp.wp_autogen_flag = 'N'                       -- predicate 5
    AND inv.inv_quantity_on_hand > 10                 -- predicate 6
    AND ts.t_hour BETWEEN 9 AND 17                     -- predicate 7
),

agg_sales AS (
  SELECT
    s_store_id,
    t_hour,
    i_item_id,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    COUNT(*) AS txn_count,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
  FROM joined_all
  GROUP BY s_store_id, t_hour, i_item_id
),

avg_store_sales AS (
  SELECT
    s_store_id,
    AVG(total_sales) AS avg_sales
  FROM agg_sales
  GROUP BY s_store_id
)

SELECT
  a.s_store_id,
  a.t_hour,
  a.i_item_id,
  a.total_sales,
  a.total_profit,
  a.txn_count,
  a.profit_flag,
  AVG(a.total_sales) OVER (PARTITION BY a.s_store_id) AS avg_sales_by_store,
  ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.total_sales DESC) AS sales_rank,
  CASE
    WHEN a.total_sales > (SELECT avg_sales FROM avg_store_sales WHERE s_store_id = a.s_store_id) THEN 'Above Avg'
    ELSE 'Below Avg'
  END AS sales_relative_to_avg
FROM agg_sales a
ORDER BY a.total_sales DESC
LIMIT 100
