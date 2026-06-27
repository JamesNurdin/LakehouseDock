WITH sales_data AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_promo_sk,
        ds.d_year,
        ds.d_moy,
        ds.d_date,
        p.p_promo_id,
        p.p_discount_active,
        hd.hd_income_band_sk,
        ca.ca_state,
        wsit.web_name
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ds.d_date >= DATE '2001-01-01'
      AND ds.d_date <= DATE '2001-12-31'
      AND p.p_discount_active = 'Y'
)
SELECT
    web_name,
    d_year,
    d_moy,
    sum(ws_ext_sales_price) AS total_sales,
    sum(ws_net_profit) AS total_profit,
    sum(ws_quantity) AS total_quantity,
    avg(ws_ext_discount_amt) AS avg_discount,
    count(distinct ws_order_number) AS distinct_orders,
    count(distinct ws_bill_customer_sk) AS distinct_customers,
    count(distinct p_promo_id) AS distinct_promotions,
    count(distinct hd_income_band_sk) AS distinct_income_bands
FROM sales_data
GROUP BY web_name, d_year, d_moy
ORDER BY web_name, d_year, d_moy
