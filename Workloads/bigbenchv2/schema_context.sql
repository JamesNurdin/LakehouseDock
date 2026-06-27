CREATE TABLE iceberg.bigbenchv2_sf1.customers (
  c_customer_id bigint,
  c_name varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.items (
  i_item_id bigint,
  i_name varchar,
  i_category_id integer,
  i_category_name varchar,
  i_price decimal(7,2),
  i_comp_price decimal(7,2),
  i_class_id bigint
);

CREATE TABLE iceberg.bigbenchv2_sf1.product_reviews (
  pr_review_id bigint,
  pr_item_id bigint,
  pr_ts varchar,
  pr_rating integer,
  pr_content varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.web_pages (
  w_web_page_id bigint,
  w_web_page_name varchar,
  w_web_page_type varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.web_sales (
  ws_transaction_id bigint,
  ws_customer_id bigint,
  ws_item_id bigint,
  ws_quantity integer,
  ws_ts varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.store_sales (
  ss_transaction_id bigint,
  ss_customer_id bigint,
  ss_store_id bigint,
  ss_item_id bigint,
  ss_quantity integer,
  ss_ts varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.stores (
  s_store_id bigint,
  s_store_name varchar
);

CREATE TABLE iceberg.bigbenchv2_sf1.web_logs (
  line varchar
);