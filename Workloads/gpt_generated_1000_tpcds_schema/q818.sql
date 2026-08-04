WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        s.s_store_name,
        i.i_product_name,
        p.p_promo_name,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        inv.inv_quantity_on_hand,
        i_ret.i_product_name AS return_product_name,
        sr.sr_return_amt,
        r.r_reason_desc,
        sr.sr_ticket_number AS sr_ticket_number
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
),
sales_keys AS (
    SELECT ss_store_sk, ss_item_sk FROM store_sales
),
return_keys AS (
    SELECT sr_store_sk, sr_item_sk FROM store_returns
),
sales_not_returns AS (
    SELECT * FROM sales_keys
    EXCEPT
    SELECT * FROM return_keys
)
SELECT
    s_store_name,
    i_product_name,
    p_promo_name,
    ca_city,
    cd_gender,
    hd_vehicle_count,
    ib_lower_bound,
    SUM(ext_sales_price) AS total_sales,
    SUM(net_profit) AS total_profit,
    SUM(return_amount) AS total_returns,
    COUNT(DISTINCT ss_ticket_number) AS distinct_sales_tickets,
    COUNT(DISTINCT sr_ticket_number) AS distinct_return_tickets,
    ROW_NUMBER() OVER (ORDER BY SUM(ext_sales_price) DESC) AS sales_rank
FROM (
    SELECT
        b.s_store_name,
        b.i_product_name,
        b.p_promo_name,
        b.ca_city,
        b.cd_gender,
        b.hd_vehicle_count,
        b.ib_lower_bound,
        b.ss_ext_sales_price AS ext_sales_price,
        b.ss_net_profit AS net_profit,
        b.sr_return_amt AS return_amount,
        b.ss_ticket_number,
        b.sr_ticket_number
    FROM base b
    JOIN sales_not_returns snr
        ON b.ss_store_sk = snr.ss_store_sk
        AND b.ss_item_sk = snr.ss_item_sk
) t
GROUP BY CUBE(s_store_name, i_product_name, p_promo_name, ca_city, cd_gender, hd_vehicle_count, ib_lower_bound)
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
