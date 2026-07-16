WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_bill_cdemo_sk AS cdemo_sk,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
),
aggregated AS (
    SELECT
        cc.cc_mkt_desc,
        d.d_year,
        d.d_month_seq AS month,
        SUM(s.net_profit) AS total_net_profit,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
        AVG(cc.cc_tax_percentage) AS avg_tax_percentage
    FROM sales_data s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    JOIN inventory i ON d.d_date_sk = i.inv_date_sk
    JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    WHERE d.d_year = 2002
      AND cd.cd_credit_rating = 'Excellent'
      AND cc.cc_manager = 'Bob Belcher'
      AND cc.cc_gmt_offset = -5.00
    GROUP BY cc.cc_mkt_desc, d.d_year, d.d_month_seq
    HAVING SUM(s.net_profit) > 50000
)
SELECT
    a.*,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.total_net_profit DESC
LIMIT 20
