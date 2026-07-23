WITH raw_data AS (
    SELECT
        d.d_year,
        cp.cp_department,
        ca.ca_state,
        cs.cs_quantity,
        cs.cs_net_profit,
        ws.ws_quantity,
        ws.ws_net_profit,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        inv.inv_quantity_on_hand,
        (cs.cs_quantity * cs.cs_net_profit) AS cs_total_profit,
        (ws.ws_quantity * ws.ws_net_profit) AS ws_total_profit,
        (sr.sr_return_quantity * sr.sr_net_loss) AS sr_total_loss
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
),
agg_data AS (
    SELECT
        d_year,
        cp_department,
        ca_state,
        SUM(cs_total_profit + ws_total_profit - sr_total_loss) AS total_net_profit,
        SUM(cs_quantity + ws_quantity - sr_return_quantity) AS total_quantity,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        CASE
            WHEN SUM(cs_total_profit + ws_total_profit - sr_total_loss) > 50000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM raw_data
    WHERE d_year = 2000
      AND ca_state = 'CA'
      AND inv_quantity_on_hand > 500
    GROUP BY d_year, cp_department, ca_state
    HAVING SUM(cs_total_profit + ws_total_profit - sr_total_loss) > 0
       AND SUM(cs_quantity + ws_quantity - sr_return_quantity) > 1000
)
SELECT
    d_year,
    cp_department,
    ca_state,
    total_net_profit,
    total_quantity,
    avg_inventory_on_hand,
    profit_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM agg_data
ORDER BY d_year, profit_rank
