WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_addr_sk,
        ss.ss_store_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_net_profit,
        i.i_item_id,
        i.i_product_name,
        i.i_color,
        i.i_manager_id,
        i.i_units,
        cd.cd_education_status,
        cd.cd_dep_employed_count,
        ca.ca_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    b.ss_ticket_number,
    b.i_item_id,
    b.i_product_name,
    b.i_color,
    b.i_manager_id,
    b.i_units,
    b.ca_state,
    b.cd_education_status,
    b.cd_dep_employed_count,
    b.ss_quantity,
    b.ss_sales_price,
    b.ss_net_profit,
    b.sr_return_quantity,
    b.sr_return_amt,
    b.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY b.i_item_id ORDER BY b.ss_sales_price DESC) AS sales_price_rank,
    RANK() OVER (PARTITION BY b.ca_state ORDER BY b.ss_net_profit DESC) AS profit_state_rank,
    SUM(b.ss_net_profit) OVER (PARTITION BY b.i_manager_id ORDER BY b.ss_sold_date_sk ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS profit_30day_moving_sum
FROM base b
WHERE b.i_color IN ('red', 'pale', 'yellow')
  AND b.i_manager_id IN (63, 25, 4)
  AND b.i_units = 'Case'
  AND b.cd_education_status IN ('College', 'Advanced Degree')
  AND b.cd_dep_employed_count >= 2
  AND b.ss_sales_price > 15.00
  AND b.ca_state = 'CA'
ORDER BY b.ss_net_profit DESC
LIMIT 100
