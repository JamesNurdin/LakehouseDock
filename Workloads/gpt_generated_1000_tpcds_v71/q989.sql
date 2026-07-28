WITH joined AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_market_manager,
        td.t_time_id,
        td.t_hour,
        td.t_am_pm,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        cs.cs_order_number,
        cs.cs_net_profit AS cs_net_profit,
        (ss.ss_net_profit + cs.cs_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_sales cs
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE td.t_am_pm = 'PM'
      AND hd.hd_buy_potential = '1001-5000'
      AND cc.cc_market_manager = 'John Melendez'
      AND td.t_hour BETWEEN 9 AND 17
),
agg AS (
    SELECT
        cc_name,
        cc_market_manager,
        t_time_id,
        t_hour,
        hd_buy_potential,
        SUM(total_net_profit) AS sum_total_net_profit
    FROM joined
    GROUP BY
        cc_name,
        cc_market_manager,
        t_time_id,
        t_hour,
        hd_buy_potential
)
SELECT
    cc_name,
    cc_market_manager,
    t_time_id,
    t_hour,
    hd_buy_potential,
    sum_total_net_profit,
    RANK() OVER (PARTITION BY cc_name ORDER BY sum_total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY
    sum_total_net_profit DESC,
    cc_name
