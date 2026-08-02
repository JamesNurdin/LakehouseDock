WITH store_side AS (
    SELECT
        COALESCE(ss.ss_store_sk, s.s_store_sk) AS store_sk,
        d.d_year,
        t.t_sub_shift,
        s.s_manager,
        ca.ca_state,
        hd.hd_buy_potential,
        ss.ss_ext_sales_price AS total_sales,
        ss.ss_quantity AS sales_cnt,
        ss.ss_net_profit AS total_profit
    FROM store_sales ss
    FULL OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    CROSS JOIN LATERAL (
        SELECT SUM(ss2.ss_ext_sales_price) AS store_total_sales
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = COALESCE(ss.ss_store_sk, s.s_store_sk)
    ) AS ss_agg
    WHERE (d.d_year = 2001 OR d.d_year IS NULL)
      AND (t.t_sub_shift = 'morning' OR t.t_sub_shift IS NULL)
      AND (hd.hd_buy_potential = '>10000' OR hd.hd_buy_potential IS NULL)
      AND (d.d_date = DATE '2001-01-01' OR d.d_date IS NULL)
),
web_side AS (
    SELECT
        ws.ws_warehouse_sk AS store_sk,
        d_sold.d_year,
        t_sold.t_sub_shift,
        s_closed.s_manager,
        ca_bill.ca_state,
        hd_bill.hd_buy_potential,
        ws.ws_ext_sales_price AS total_sales,
        ws.ws_quantity AS sales_cnt,
        ws.ws_net_profit AS total_profit
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_returned_date_sk = d_sold.d_date_sk
       AND wr.wr_returned_time_sk = t_sold.t_time_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN store s_closed
        ON s_closed.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND t_sold.t_sub_shift = 'morning'
      AND hd_bill.hd_buy_potential = '>10000'
      AND d_sold.d_date = DATE '2001-01-01'
),
sales_union AS (
    SELECT
        store_sk,
        d_year,
        t_sub_shift,
        s_manager,
        ca_state,
        hd_buy_potential,
        total_sales,
        sales_cnt,
        total_profit
    FROM store_side
    UNION ALL
    SELECT
        store_sk,
        d_year,
        t_sub_shift,
        s_manager,
        ca_state,
        hd_buy_potential,
        total_sales,
        sales_cnt,
        total_profit
    FROM web_side
)
SELECT
    manager,
    year,
    MAX(sub_shift) AS sub_shift,
    MAX(state) AS state,
    MAX(buy_potential) AS buy_potential,
    COUNT(*) AS record_cnt,
    SUM(total_sales) AS sum_total_sales,
    AVG(total_sales) AS avg_total_sales,
    SUM(sales_cnt) AS sum_quantity,
    SUM(total_profit) AS sum_total_profit,
    GROUPING(manager) AS grp_manager,
    GROUPING(year) AS grp_year
FROM (
    SELECT
        s_manager AS manager,
        d_year AS year,
        t_sub_shift AS sub_shift,
        ca_state AS state,
        hd_buy_potential AS buy_potential,
        total_sales,
        sales_cnt,
        total_profit
    FROM sales_union
) us
WHERE total_sales > (
    SELECT AVG(total_sales) FROM sales_union
)
  AND EXISTS (
    SELECT 1 FROM store s2
    WHERE s2.s_manager = us.manager
      AND s2.s_number_employees > 50
)
GROUP BY ROLLUP(manager, year)
ORDER BY sum_total_sales DESC
LIMIT 100
