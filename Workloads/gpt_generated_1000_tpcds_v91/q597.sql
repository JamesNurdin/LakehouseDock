WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (5)
),
joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_sold_date_sk,
        i.i_brand,
        i.i_category,
        i.i_item_id,
        ca.ca_state,
        ca.ca_address_sk,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        inv.inv_quantity_on_hand,
        cc.cc_name,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_quantity AS ws_quantity,
        wp.wp_type,
        web_site.web_name,
        d.d_year
    FROM sampled_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web_site ON ws.ws_web_site_sk = web_site.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ib.ib_upper_bound > 100000
      AND hd.hd_vehicle_count >= 0
      AND cc.cc_name LIKE '%Center%'
)
SELECT
    i_brand,
    vehicle_status,
    total_sales_qty,
    total_return_qty,
    total_net_profit,
    distinct_items,
    distinct_customers,
    profit_level,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM (
    SELECT
        i_brand,
        CASE WHEN hd_vehicle_count > 0 THEN 'VehicleOwner' ELSE 'NoVehicle' END AS vehicle_status,
        SUM(ss_quantity) AS total_sales_qty,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(ss_net_profit) - SUM(sr_return_amt) AS total_net_profit,
        COUNT(DISTINCT i_item_id) AS distinct_items,
        COUNT(DISTINCT ca_address_sk) AS distinct_customers,
        CASE
            WHEN (SUM(ss_net_profit) - SUM(sr_return_amt)) > (SELECT AVG(ws_net_profit) FROM web_sales)
                THEN 'AboveAvg'
            ELSE 'BelowAvg'
        END AS profit_level
    FROM joined_data
    GROUP BY i_brand,
             CASE WHEN hd_vehicle_count > 0 THEN 'VehicleOwner' ELSE 'NoVehicle' END
) agg
ORDER BY profit_rank
LIMIT 100
