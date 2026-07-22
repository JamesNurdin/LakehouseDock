WITH sales_and_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_wholesale_cost,
        ss.ss_ext_list_price,
        ss.ss_ext_discount_amt,
        wr.wr_net_loss,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        hd_s.hd_buy_potential AS sales_buy_potential,
        hd_s.hd_vehicle_count,
        hd_s.hd_dep_count,
        hd_wr.hd_buy_potential AS returns_buy_potential,
        hd_wr.hd_dep_count AS returns_dep_count,
        td.t_sub_shift,
        td.t_hour,
        CASE WHEN hd_s.hd_vehicle_count >= 2 THEN '2plus' ELSE '0or1' END AS vehicle_category
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd_s
        ON ss.ss_hdemo_sk = hd_s.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd_wr
        ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
    WHERE td.t_sub_shift = 'morning'
      AND td.t_hour BETWEEN 8 AND 12
      AND hd_s.hd_vehicle_count >= 1
      AND hd_s.hd_dep_count BETWEEN 2 AND 5
      AND ss.ss_wholesale_cost > 50.00
      AND ss.ss_ext_list_price < 500.00
      AND wr.wr_return_amt > 100.00
      AND wr.wr_return_quantity >= 1
)
SELECT
    sales_buy_potential,
    returns_buy_potential,
    t_sub_shift,
    vehicle_category,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_tickets,
    SUM(ss_net_paid) AS total_net_paid,
    AVG(ss_net_profit) AS avg_net_profit,
    SUM(wr_net_loss) AS total_return_loss,
    COUNT(wr_return_quantity) AS total_return_quantity,
    MAX(returns_dep_count) AS max_return_household_dep_count,
    SUM(CASE WHEN ss_ext_discount_amt > 0 THEN ss_ext_discount_amt ELSE 0 END) AS total_discount_amount
FROM sales_and_returns
GROUP BY
    sales_buy_potential,
    returns_buy_potential,
    t_sub_shift,
    vehicle_category
ORDER BY total_net_paid DESC
LIMIT 100
