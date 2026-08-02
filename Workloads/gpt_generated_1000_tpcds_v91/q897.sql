/* Goal: Identify high‑profit catalog and web orders that meet specific catalog type, address type and quantity criteria, rank them within each state, and intersect these with orders whose cumulative catalog profit exceeds a threshold, returning the top 100 rows. */
WITH base_all AS (
    SELECT
        t.t_time_sk AS t_time_sk,
        t.t_hour AS t_hour,
        cp.cp_catalog_number AS cp_catalog_number,
        cp.cp_type AS cp_type,
        cs.cs_order_number AS cs_order_number,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        cr.cr_return_amount AS cr_return_amount,
        ca.ca_state AS ca_state,
        ca.ca_location_type AS ca_location_type,
        ca.ca_zip AS ca_zip,
        sr.sr_return_quantity AS sr_return_quantity,
        sr.sr_net_loss AS sr_net_loss,
        ws.ws_order_number AS ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wr.wr_return_quantity AS wr_return_quantity,
        wr.wr_net_loss AS wr_net_loss,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cs.cs_net_profit DESC) AS rn_state,
        SUM(cs.cs_net_profit) OVER (PARTITION BY cp.cp_catalog_number ORDER BY t.t_time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_catalog
    FROM tpcds.time_dim t
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.store_returns sr ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_sales ws ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
)
(
    SELECT
        t_time_sk,
        t_hour,
        cp_catalog_number,
        cp_type,
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_net_profit,
        cr_return_amount,
        ca_state,
        ca_location_type,
        ca_zip,
        sr_return_quantity,
        sr_net_loss,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        wr_return_quantity,
        wr_net_loss,
        rn_state,
        cum_profit_by_catalog
    FROM base_all
    WHERE cp_type = 'monthly'
      AND ca_location_type = 'apartment'
      AND cs_quantity > 5
      AND cr_return_amount > 50

    UNION ALL

    SELECT
        t_time_sk,
        t_hour,
        cp_catalog_number,
        cp_type,
        cs_order_number,
        cs_item_sk,
        cs_quantity,
        cs_net_profit,
        cr_return_amount,
        ca_state,
        ca_location_type,
        ca_zip,
        sr_return_quantity,
        sr_net_loss,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        wr_return_quantity,
        wr_net_loss,
        rn_state,
        cum_profit_by_catalog
    FROM base_all
    WHERE cp_type = 'quarterly'
      AND ca_location_type = 'condo'
      AND cs_quantity <= 5
      AND cr_return_amount > 0
)
INTERSECT
SELECT
    t_time_sk,
    t_hour,
    cp_catalog_number,
    cp_type,
    cs_order_number,
    cs_item_sk,
    cs_quantity,
    cs_net_profit,
    cr_return_amount,
    ca_state,
    ca_location_type,
    ca_zip,
    sr_return_quantity,
    sr_net_loss,
    ws_order_number,
    ws_quantity,
    ws_net_profit,
    wr_return_quantity,
    wr_net_loss,
    rn_state,
    cum_profit_by_catalog
FROM base_all
WHERE cum_profit_by_catalog > 1000
LIMIT 100
