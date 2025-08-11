ALTER TABLE customer
ADD CONSTRAINT c_current_hdemo_sk_household_demographics_hd_demo_sk FOREIGN KEY (c_current_hdemo_sk) REFERENCES household_demographics (hd_demo_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_item_sk_item_i_item_sk FOREIGN KEY (cs_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE customer
ADD CONSTRAINT c_current_cdemo_sk_customer_demographics_cd_demo_sk FOREIGN KEY (c_current_cdemo_sk) REFERENCES customer_demographics (cd_demo_sk);


ALTER TABLE web_site
ADD CONSTRAINT web_close_date_sk_date_dim_d_date_sk FOREIGN KEY (web_close_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE promotion
ADD CONSTRAINT p_start_date_sk_date_dim_d_date_sk FOREIGN KEY (p_start_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_return_time_sk_time_dim_t_time_sk FOREIGN KEY (sr_return_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE household_demographics
ADD CONSTRAINT hd_income_band_sk_income_band_ib_income_band_sk FOREIGN KEY (hd_income_band_sk) REFERENCES income_band (ib_income_band_sk);


ALTER TABLE web_site
ADD CONSTRAINT web_open_date_sk_date_dim_d_date_sk FOREIGN KEY (web_open_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_sold_date_sk_date_dim_d_date_sk FOREIGN KEY (ss_sold_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_page
ADD CONSTRAINT wp_creation_date_sk_date_dim_d_date_sk FOREIGN KEY (wp_creation_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_returned_date_sk_date_dim_d_date_sk FOREIGN KEY (wr_returned_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_item_sk_item_i_item_sk FOREIGN KEY (sr_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_catalog_page_sk_catalog_page_cp_catalog_page_sk FOREIGN KEY (cs_catalog_page_sk) REFERENCES catalog_page (cp_catalog_page_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_sold_time_sk_time_dim_t_time_sk FOREIGN KEY (ws_sold_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_web_site_sk_web_site_web_site_sk FOREIGN KEY (ws_web_site_sk) REFERENCES web_site (web_site_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_item_sk_item_i_item_sk FOREIGN KEY (wr_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE store
ADD CONSTRAINT s_closed_date_sk_date_dim_d_date_sk FOREIGN KEY (s_closed_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_customer_sk_customer_c_customer_sk FOREIGN KEY (sr_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_returned_time_sk_time_dim_t_time_sk FOREIGN KEY (wr_returned_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_ship_date_sk_date_dim_d_date_sk FOREIGN KEY (ws_ship_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE customer
ADD CONSTRAINT c_first_shipto_date_sk_date_dim_d_date_sk FOREIGN KEY (c_first_shipto_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_page
ADD CONSTRAINT wp_access_date_sk_date_dim_d_date_sk FOREIGN KEY (wp_access_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_promo_sk_promotion_p_promo_sk FOREIGN KEY (ss_promo_sk) REFERENCES promotion (p_promo_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_warehouse_sk_warehouse_w_warehouse_sk FOREIGN KEY (cs_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);


ALTER TABLE web_page
ADD CONSTRAINT wp_customer_sk_customer_c_customer_sk FOREIGN KEY (wp_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_web_page_sk_web_page_wp_web_page_sk FOREIGN KEY (ws_web_page_sk) REFERENCES web_page (wp_web_page_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_returned_date_sk_date_dim_d_date_sk FOREIGN KEY (sr_returned_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE customer
ADD CONSTRAINT c_first_sales_date_sk_date_dim_d_date_sk FOREIGN KEY (c_first_sales_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_store_sk_store_s_store_sk FOREIGN KEY (sr_store_sk) REFERENCES store (s_store_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_returned_time_sk_time_dim_t_time_sk FOREIGN KEY (cr_returned_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_sold_date_sk_date_dim_d_date_sk FOREIGN KEY (cs_sold_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_sold_time_sk_time_dim_t_time_sk FOREIGN KEY (cs_sold_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_refunded_customer_sk_customer_c_customer_sk FOREIGN KEY (wr_refunded_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_customer_sk_customer_c_customer_sk FOREIGN KEY (ss_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_warehouse_sk_warehouse_w_warehouse_sk FOREIGN KEY (ws_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);


ALTER TABLE call_center
ADD CONSTRAINT cc_closed_date_sk_date_dim_d_date_sk FOREIGN KEY (cc_closed_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_returns
ADD CONSTRAINT sr_reason_sk_reason_r_reason_sk FOREIGN KEY (sr_reason_sk) REFERENCES reason (r_reason_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_ship_mode_sk_ship_mode_sm_ship_mode_sk FOREIGN KEY (cs_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);


ALTER TABLE promotion
ADD CONSTRAINT p_end_date_sk_date_dim_d_date_sk FOREIGN KEY (p_end_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_web_page_sk_web_page_wp_web_page_sk FOREIGN KEY (wr_web_page_sk) REFERENCES web_page (wp_web_page_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_item_sk_item_i_item_sk FOREIGN KEY (ss_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_ship_mode_sk_ship_mode_sm_ship_mode_sk FOREIGN KEY (ws_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_item_sk_item_i_item_sk FOREIGN KEY (cr_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE promotion
ADD CONSTRAINT p_item_sk_item_i_item_sk FOREIGN KEY (p_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_reason_sk_reason_r_reason_sk FOREIGN KEY (cr_reason_sk) REFERENCES reason (r_reason_sk);


ALTER TABLE inventory
ADD CONSTRAINT inv_warehouse_sk_warehouse_w_warehouse_sk FOREIGN KEY (inv_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_ship_mode_sk_ship_mode_sm_ship_mode_sk FOREIGN KEY (cr_ship_mode_sk) REFERENCES ship_mode (sm_ship_mode_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_refunded_customer_sk_customer_c_customer_sk FOREIGN KEY (cr_refunded_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_sold_time_sk_time_dim_t_time_sk FOREIGN KEY (ss_sold_time_sk) REFERENCES time_dim (t_time_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_bill_customer_sk_customer_c_customer_sk FOREIGN KEY (ws_bill_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_reason_sk_reason_r_reason_sk FOREIGN KEY (wr_reason_sk) REFERENCES reason (r_reason_sk);


ALTER TABLE catalog_page
ADD CONSTRAINT cp_end_date_sk_date_dim_d_date_sk FOREIGN KEY (cp_end_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE catalog_page
ADD CONSTRAINT cp_start_date_sk_date_dim_d_date_sk FOREIGN KEY (cp_start_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE store_sales
ADD CONSTRAINT ss_store_sk_store_s_store_sk FOREIGN KEY (ss_store_sk) REFERENCES store (s_store_sk);


ALTER TABLE customer
ADD CONSTRAINT c_current_addr_sk_customer_address_ca_address_sk FOREIGN KEY (c_current_addr_sk) REFERENCES customer_address (ca_address_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_sold_date_sk_date_dim_d_date_sk FOREIGN KEY (ws_sold_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_call_center_sk_call_center_cc_call_center_sk FOREIGN KEY (cr_call_center_sk) REFERENCES call_center (cc_call_center_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_ship_customer_sk_customer_c_customer_sk FOREIGN KEY (cs_ship_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_returned_date_sk_date_dim_d_date_sk FOREIGN KEY (cr_returned_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_catalog_page_sk_catalog_page_cp_catalog_page_sk FOREIGN KEY (cr_catalog_page_sk) REFERENCES catalog_page (cp_catalog_page_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_ship_customer_sk_customer_c_customer_sk FOREIGN KEY (ws_ship_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE call_center
ADD CONSTRAINT cc_open_date_sk_date_dim_d_date_sk FOREIGN KEY (cc_open_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_item_sk_item_i_item_sk FOREIGN KEY (ws_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE web_returns
ADD CONSTRAINT wr_returning_customer_sk_customer_c_customer_sk FOREIGN KEY (wr_returning_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE catalog_returns
ADD CONSTRAINT cr_warehouse_sk_warehouse_w_warehouse_sk FOREIGN KEY (cr_warehouse_sk) REFERENCES warehouse (w_warehouse_sk);


ALTER TABLE inventory
ADD CONSTRAINT inv_item_sk_item_i_item_sk FOREIGN KEY (inv_item_sk) REFERENCES item (i_item_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_bill_customer_sk_customer_c_customer_sk FOREIGN KEY (cs_bill_customer_sk) REFERENCES customer (c_customer_sk);


ALTER TABLE catalog_sales
ADD CONSTRAINT cs_ship_date_sk_date_dim_d_date_sk FOREIGN KEY (cs_ship_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE inventory
ADD CONSTRAINT inv_date_sk_date_dim_d_date_sk FOREIGN KEY (inv_date_sk) REFERENCES date_dim (d_date_sk);


ALTER TABLE web_sales
ADD CONSTRAINT ws_promo_sk_promotion_p_promo_sk FOREIGN KEY (ws_promo_sk) REFERENCES promotion (p_promo_sk);