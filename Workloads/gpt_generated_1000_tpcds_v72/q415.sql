WITH sales_returns AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_addr_sk,
        cd.cd_gender,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ca.ca_state,
        td.t_hour,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
       AND ss.ss_item_sk = sr.sr_item_sk
)
SELECT
    ca_state,
    ib_lower_bound,
    ib_upper_bound,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT ss_ticket_number) AS num_transactions,
    AVG(CASE WHEN ss_net_profit > 0 THEN ss_net_profit END) AS avg_positive_profit,
    MAX(CASE WHEN sr_return_quantity IS NOT NULL THEN sr_return_quantity ELSE 0 END) AS max_return_qty,
    CASE
        WHEN SUM(ss_net_profit) > (SELECT AVG(ss_net_profit) FROM store_sales)
        THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM sales_returns
WHERE
    t_hour BETWEEN 9 AND 17
    AND cd_gender = 'M'
    AND hd_vehicle_count >= 2
    AND ib_upper_bound <= 150000
GROUP BY
    ca_state,
    ib_lower_bound,
    ib_upper_bound
HAVING
    SUM(ss_ext_sales_price) > 100000
    AND COUNT(DISTINCT ss_ticket_number) >= 10
ORDER BY
    total_sales DESC
LIMIT 100
