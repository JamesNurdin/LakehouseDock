WITH sales_base AS (
    SELECT
        d.d_date,
        d.d_year,
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        cs.cs_order_number,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        ca.ca_state,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_name,
        rs.r_reason_desc,
        ws.ws_order_number,
        inv.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC) AS profit_rank,
        (
            SELECT SUM(cs2.cs_ext_sales_price)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = ss.ss_item_sk
        ) AS total_catalog_sales_price
    FROM date_dim d
    -- 1. store_sales (base sales fact)
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    -- 2. store_returns linked by ticket number
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    -- 3. reason for the return
    LEFT JOIN reason rs
        ON rs.r_reason_sk = sr.sr_reason_sk
    -- 4. catalog_sales (another sales channel) on the same date key
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    -- 5. catalog_returns linked to catalog_sales by order number and item
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    -- 6. web_sales sampled with Bernoulli (10% of rows)
    LEFT JOIN (
        SELECT * FROM web_sales TABLESAMPLE BERNOULLI (10)
    ) ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    -- 7. item dimension (joined via store_sales item key)
    LEFT JOIN item i
        ON i.i_item_sk = ss.ss_item_sk
    -- 8. promotion linked to store_sales
    LEFT JOIN promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
    -- 9. household demographics linked to store_sales
    LEFT JOIN household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
    -- 10. income band for the household
    LEFT JOIN income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    -- 11. customer address linked to store_sales
    LEFT JOIN customer_address ca
        ON ca.ca_address_sk = ss.ss_addr_sk
    -- 12. inventory (date + item combination)
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_qoy = 2                           -- filter 1: quarter of year
      AND ss.ss_quantity > 1                    -- filter 2: minimum quantity sold
      AND i.i_current_price > 100               -- filter 3: price threshold
      AND cs.cs_order_number NOT IN (           -- anti‑semi‑join: orders without a return
            SELECT cr2.cr_order_number FROM catalog_returns cr2
        )
)
SELECT
    d_date,
    d_year,
    i_item_id,
    i_product_name,
    i_current_price,
    ss_quantity,
    ss_net_profit,
    ca_state,
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    p_promo_name,
    r_reason_desc,
    ws_order_number,
    inv_quantity_on_hand,
    total_catalog_sales_price,
    profit_rank
FROM sales_base
WHERE profit_rank <= 100
ORDER BY profit_rank ASC
LIMIT 100
